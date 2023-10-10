package store

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) Create_Category_Table() error {
	// fmt.Println("Entered CreateHigherLevelCategoryTable")

	query := `create table if not exists category (
		id SERIAL PRIMARY KEY,
    	name VARCHAR(100) NOT NULL UNIQUE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := s.db.Exec(query)

	// fmt.Println("Exiting CreateHigherLevelCategoryTable")

	return err
}

func (s *PostgresStore) Create_Category(hlc *types.Category) (*types.Category, error) {
	// 1. Check if a category with the same name already exists
	checkQuery := `SELECT id, name, created_at, created_by FROM category WHERE name = $1`
	rows, err := s.db.Query(checkQuery, hlc.Name)
	if err != nil {
		return nil, err
	}

	existingCats := []*types.Category{}

	for rows.Next() {
		existingCat, err := scan_Into_Category(rows)
		if err != nil && err != sql.ErrNoRows {
			return nil, err
		}
		existingCats = append(existingCats, existingCat)
	}

	// 2. Return the existing category if found
	if len(existingCats) > 0 {
		return existingCats[0], nil
	}

	query := `insert into category
	(name, created_by) 
	values ($1, $2) returning id, name, created_at, created_by
	`
	rows, err = s.db.Query(
		query,
		hlc.Name,
		hlc.Created_By)

	fmt.Println("CheckPoint 1")

	if err != nil {
		return nil, err
	}

	fmt.Println("CheckPoint 2")

	categories := []*types.Category{}

	for rows.Next() {
		category, err := scan_Into_Category(rows)
		if err != nil {
			return nil, err
		}
		categories = append(categories, category)
	}

	fmt.Println("CheckPoint 3")

	return categories[0], nil
}

func (s *PostgresStore) Get_Categories() ([]*types.Category, error) {
	rows, err := s.db.Query("select * from category")
	if err != nil {
		return nil, err
	}

	categories := []*types.Category{}
	for rows.Next() {
		category, err := scan_Into_Category(rows)
		if err != nil {
			return nil, err
		}
		categories = append(categories, category)
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

	categoryQuery := "select name, id from category where id = ANY($1::integer[])"

	rows, err = s.db.Query(categoryQuery, pq.Array(childIDs))
	if err != nil {
		log.Fatal(err)
	}

	defer rows.Close()

	categories := []*types.Update_Category{}

	for rows.Next() {
		category, err := scan_Into_Update_Category(rows)
		if err != nil {
			return nil, err
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
	_, err := s.db.Query("delete from category where id = $1", id)
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
