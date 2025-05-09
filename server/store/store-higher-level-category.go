package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateHigherLevelCategoryTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateHigherLevelCategoryTable")

	// Create the higher_level_category table
	query := `CREATE TABLE IF NOT EXISTS higher_level_category (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by INT
    );`
	_, err := tx.Exec(query)
	if err != nil {
		return err
	}

	// Create a unique index on the lowercased name to ensure case-sensitive uniqueness
	uniqueIndexQuery := `CREATE UNIQUE INDEX IF NOT EXISTS higher_level_category_name_unique ON higher_level_category (LOWER(name));`
	_, err = tx.Exec(uniqueIndexQuery)
	if err != nil {
		return err
	}

	// fmt.Println("Exiting CreateHigherLevelCategoryTable")
	return nil
}

func (s *PostgresStore) CreateHigherLevelCategoryImageTable(tx *sql.Tx) error {
	query := `
	create table if not exists higher_level_category_image (
		higher_level_category_id INT REFERENCES higher_level_category(id),
		image TEXT NOT NULL,
		position INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT,
		PRIMARY KEY (higher_level_category_id, position)
	)`

	_, err := tx.Exec(query)
	return err
}

func (s *PostgresStore) Get_Higher_Level_Categories() ([]*types.Higher_Level_Category, error) {
	query := `
    SELECT c.id, c.name, ci.image, ci.position, c.created_at, c.created_by 
    FROM higher_level_category c
    LEFT JOIN higher_level_category_image ci ON c.id = ci.higher_level_category_id AND ci.position = 1
    ORDER BY c.id ASC` // Added ORDER BY clause here

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	categories := []*types.Higher_Level_Category{}
	for rows.Next() {
		var (
			id        int
			name      string
			image     sql.NullString // Placeholder variable for image
			position  sql.NullInt64  // Placeholder variable for position
			createdAt string
			createdBy sql.NullInt64 // Placeholder variable for createdBy
		)

		err := rows.Scan(&id, &name, &image, &position, &createdAt, &createdBy)
		if err != nil {
			return nil, err
		}

		// Create a new category and assign values, converting SQL nulls as needed
		category := &types.Higher_Level_Category{
			ID:         id,
			Name:       name,
			Image:      "", // Default to empty string
			Position:   0,  // Default to 0
			Created_At: createdAt,
			Created_By: 0, // Default to 0 or another value that represents "null" for your use case
		}

		// Only overwrite Image and Position if valid (not NULL)
		if image.Valid {
			category.Image = image.String
		}
		if position.Valid {
			category.Position = int(position.Int64) // Convert to int if your struct expects an int
		}
		if createdBy.Valid {
			category.Created_By = int(createdBy.Int64) // Convert to int
		}

		categories = append(categories, category)
	}

	return categories, nil
}

func (s *PostgresStore) Get_Higher_Level_Category_By_ID(id int) (*types.Higher_Level_Category, error) {
	row, err := s.db.Query("select * from higher_level_category where id = $1", id)
	if err != nil {
		return nil, err
	}

	for row.Next() {
		return scan_Into_Higher_Level_Category(row)
	}

	return nil, fmt.Errorf("higher_level_category with id = [%d] not found", id)
}

func (s *PostgresStore) Update_Higher_Level_Category(hlc *types.Update_Higher_Level_Category) (*types.Update_Higher_Level_Category, error) {
	query := `update higher_level_category
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

	higher_level_categories := []*types.Update_Higher_Level_Category{}

	for rows.Next() {
		higher_level_category, err := scan_Into_Update_Higher_Level_Category(rows)
		if err != nil {
			return nil, err
		}
		higher_level_categories = append(higher_level_categories, higher_level_category)
	}

	return higher_level_categories[0], nil
}

func (s *PostgresStore) Delete_Higher_Level_Category(id int) error {
	_, err := s.db.Exec("DELETE FROM category_higher_level_mapping WHERE higher_level_category_id = $1", id)
	if err != nil {
		return err
	}

	_, err = s.db.Exec("DELETE FROM higher_level_category_image WHERE higher_level_category_id = $1", id)
	if err != nil {
		return err
	}
	_, err = s.db.Exec("DELETE FROM higher_level_category WHERE id = $1", id)
	return err
}

func scan_Into_Higher_Level_Category(rows *sql.Rows) (*types.Higher_Level_Category, error) {
	higher_level_category := new(types.Higher_Level_Category)
	err := rows.Scan(
		&higher_level_category.ID,
		&higher_level_category.Name,
		&higher_level_category.Created_At,
		&higher_level_category.Created_By,
	)

	return higher_level_category, err
}

func scan_Into_Update_Higher_Level_Category(rows *sql.Rows) (*types.Update_Higher_Level_Category, error) {
	higher_level_category := new(types.Update_Higher_Level_Category)
	error := rows.Scan(
		&higher_level_category.Name,
		&higher_level_category.ID,
	)

	return higher_level_category, error
}
