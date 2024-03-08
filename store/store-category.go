package store

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) Create_Category_Table(tx *sql.Tx) error {
	// fmt.Println("Entered Create_Category_Table")

	// Create the category table
	query := `CREATE TABLE IF NOT EXISTS category (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,      
        promotion BOOLEAN DEFAULT FALSE,        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by INT
    );`
	_, err := tx.Exec(query)
	if err != nil {
		return err
	}

	// Create a unique index on the lowercased name to ensure case-sensitive uniqueness
	uniqueIndexQuery := `CREATE UNIQUE INDEX IF NOT EXISTS category_name_unique ON category (LOWER(name));`
	_, err = tx.Exec(uniqueIndexQuery)
	if err != nil {
		return err
	}

	// fmt.Println("Exiting Create_Category_Table")
	return nil
}

func (s *PostgresStore) Create_Category_Image_Table(tx *sql.Tx) error {
	query := `
	create table if not exists category_image (
		category_id INT REFERENCES category(id),
		image TEXT NOT NULL,
		position INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT,
		PRIMARY KEY (category_id, position)
	)`

	_, err := tx.Exec(query)
	return err
}

func (s *PostgresStore) Create_Category(hlc *types.Category) (*types.Category, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// 1. Check if a category with the same name already exists
	checkQuery := `SELECT id, name, promotion, created_at, created_by FROM category WHERE name = $1`
	existingCat := &types.Category{}
	err = tx.QueryRow(checkQuery, hlc.Name).Scan(&existingCat.ID, &existingCat.Name, &existingCat.Promotion, &existingCat.Created_At, &existingCat.Created_By)

	// If category is found, then also fetch the image info
	if err == nil {
		imageQuery := `SELECT image, position FROM category_image WHERE category_id = $1`
		err = tx.QueryRow(imageQuery, existingCat.ID).Scan(&existingCat.Image, &existingCat.Position)
		if err != nil {
			return nil, err
		}
		return existingCat, nil
	} else if err != sql.ErrNoRows {
		return nil, err
	}

	// 2. If no existing category is found, then insert new category
	categoryInsertQuery := `
	INSERT INTO category (name, promotion, created_by) 
	VALUES ($1, $2, $3) 
	RETURNING id, name, promotion, created_at, created_by`

	result := &types.Category{}
	err = tx.QueryRow(categoryInsertQuery, hlc.Name, hlc.Promotion, hlc.Created_By).Scan(&result.ID, &result.Name, &result.Promotion, &result.Created_At, &result.Created_By)
	if err != nil {
		return nil, err
	}

	// Inserting default image at position 1 in category_image and returning the fields
	imageInsertQuery := `
	INSERT INTO category_image (category_id, image, position, created_by)
	VALUES ($1, $2, $3, $4)
	RETURNING image, position`

	err = tx.QueryRow(imageInsertQuery, result.ID, hlc.Image, 1, hlc.Created_By).Scan(&result.Image, &result.Position)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		return nil, err
	}

	return result, nil
}

func (s *PostgresStore) Get_Categories(promotion bool) ([]*types.Category, error) {
	query := `
        SELECT c.id, c.name, c.promotion, ci.image, COALESCE(ci.position, 0) AS position, c.created_at, COALESCE(c.created_by, 0) AS created_by
        FROM category c
        LEFT JOIN category_image ci ON c.id = ci.category_id AND ci.position = 1
        WHERE c.promotion = $1
    `

	rows, err := s.db.Query(query, promotion)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categories []*types.Category
	for rows.Next() {
		var (
			id        int
			name      string
			promotion bool
			image     *string // Change this to a pointer to a string
			position  int
			createdAt time.Time
			createdBy int
		)

		err := rows.Scan(
			&id,
			&name,
			&promotion,
			&image, // Keep this as a pointer
			&position,
			&createdAt,
			&createdBy,
		)
		if err != nil {
			return nil, err
		}

		// Check if image pointer is nil; if so, use an empty string
		imageValue := ""
		if image != nil {
			imageValue = *image
		}

		categories = append(categories, &types.Category{
			ID:         id,
			Name:       name,
			Promotion:  promotion,
			Image:      imageValue, // Use the dereferenced value or an empty string
			Position:   position,
			Created_At: createdAt,
			Created_By: createdBy,
		})
	}

	return categories, nil
}

func (s *PostgresStore) Get_Category_By_Parent_ID(id int) ([]*types.Update_Category, error) {
	rows, err := s.db.Query("select category_id from category_higher_level_mapping where higher_level_category_id = $1", id)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	var childIDs []int

	for rows.Next() {
		var childID int
		if err := rows.Scan(&childID); err != nil {
			log.Fatal(err)
		}
		childIDs = append(childIDs, childID)
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	categoryQuery := `
    SELECT c.name, c.id, ci.image 
    FROM category c 
    LEFT JOIN category_image ci ON c.id = ci.category_id AND ci.position = 1 
    WHERE c.id = ANY($1::integer[])`

	rows, err = s.db.Query(categoryQuery, pq.Array(childIDs))
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	categories := []*types.Update_Category{}

	for rows.Next() {
		var image sql.NullString // Use sql.NullString to handle possible NULL values
		category := &types.Update_Category{}

		err := rows.Scan(&category.Name, &category.ID, &image) // Scan the image into sql.NullString
		if err != nil {
			return nil, err
		}

		if image.Valid {
			category.Image = image.String // If image is not NULL, assign its value
		} else {
			category.Image = "" // If image is NULL, assign an empty string
		}

		categories = append(categories, category)
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	return categories, nil
}

func (s *PostgresStore) Get_Category_By_ID(id int) (*types.Category, error) {
	row, err := s.db.Query("select * from category where id = $1", id)
	if err != nil {
		return nil, err
	}

	for row.Next() {
		return scan_Into_Category(row)
	}

	return nil, fmt.Errorf("category with id = [%d] not found", id)
}

func (s *PostgresStore) Update_Category(hlc *types.Update_Category) (*types.Update_Category, error) {
	query := `update category
	set name = $1
	where id = $2 
	returning name, id`

	rows, err := s.db.Query(
		query,
		hlc.Name,
		hlc.ID,
	)
	if err != nil {
		return nil, err
	}

	categories := []*types.Update_Category{}

	for rows.Next() {
		category, err := scan_Into_Update_Category(rows)
		if err != nil {
			return nil, err
		}
		categories = append(categories, category)
	}

	return categories[0], nil
}

func (s *PostgresStore) Delete_Category(id int) error {
	_, err := s.db.Exec("DELETE FROM category_higher_level_mapping WHERE category_id = $1", id)
	if err != nil {
		return err
	}
	// First, delete (or update) related rows in category_image
	_, err = s.db.Exec("DELETE FROM category_image WHERE category_id = $1", id)
	if err != nil {
		return err
	}

	// Now, delete the row from category
	_, err = s.db.Exec("DELETE FROM category WHERE id = $1", id)
	return err
}

func scan_Into_Category(rows *sql.Rows) (*types.Category, error) {
	category := new(types.Category)
	err := rows.Scan(
		&category.ID,
		&category.Name,
		&category.Created_At,
		&category.Created_By,
	)

	return category, err
}

func scan_Into_Update_Category(rows *sql.Rows) (*types.Update_Category, error) {
	category := new(types.Update_Category)
	error := rows.Scan(
		&category.Name,
		&category.ID,
	)

	return category, error
}

type Category struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

func (s *PostgresStore) GetCategoriesList() ([]Category, error) {
	var categories []Category

	query := `SELECT id, name FROM category`
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error querying categories: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var cat Category
		if err := rows.Scan(&cat.ID, &cat.Name); err != nil {
			return nil, fmt.Errorf("error scanning category row: %w", err)
		}
		categories = append(categories, cat)
	}

	// Check for errors from iterating over rows
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating category rows: %w", err)
	}

	return categories, nil
}
