package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateHigherLevelCategoryTable() error {
	// fmt.Println("Entered CreateHigherLevelCategoryTable")

	query := `create table if not exists higher_level_category (
		id SERIAL PRIMARY KEY,
    	name VARCHAR(100) NOT NULL UNIQUE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := s.db.Exec(query)

	// fmt.Println("Exiting CreateHigherLevelCategoryTable")

	return err
}

func (s *PostgresStore) Create_Higher_Level_Category(hlc *types.Higher_Level_Category) (*types.Higher_Level_Category, error) {
	// 1. Check if a higher_level_category with the same name already exists
	checkQuery := `SELECT id, name, created_at, created_by FROM higher_level_category WHERE name = $1`
	rows, err := s.db.Query(checkQuery, hlc.Name)
	if err != nil {
		return nil, err
	}

	existingHLCs := []*types.Higher_Level_Category{}
	for rows.Next() {
		existingHLC, err := scan_Into_Higher_Level_Category(rows)
		if err != nil && err != sql.ErrNoRows {
			return nil, err
		}
		existingHLCs = append(existingHLCs, existingHLC)
	}

	// 2. Return the existing higher_level_category if found
	if len(existingHLCs) > 0 {
		return existingHLCs[0], nil
	}

	query := `INSERT INTO higher_level_category
        (name, created_by) 
        VALUES ($1, $2) RETURNING id, name, created_at, created_by`

	rows, err = s.db.Query(query, hlc.Name, hlc.Created_By)
	if err != nil {
		return nil, err
	}

	higher_level_categories := []*types.Higher_Level_Category{}
	for rows.Next() {
		higher_level_category, err := scan_Into_Higher_Level_Category(rows)
		if err != nil {
			return nil, err
		}
		higher_level_categories = append(higher_level_categories, higher_level_category)
	}

	return higher_level_categories[0], nil
}

func (s *PostgresStore) Get_Higher_Level_Categories() ([]*types.Higher_Level_Category, error) {
	rows, err := s.db.Query("select * from higher_level_category")
	if err != nil {
		return nil, err
	}

	higher_level_categories := []*types.Higher_Level_Category{}
	for rows.Next() {
		higher_level_category, err := scan_Into_Higher_Level_Category(rows)
		if err != nil {
			return nil, err
		}
		higher_level_categories = append(higher_level_categories, higher_level_category)
	}

	return higher_level_categories, nil
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
	_, err := s.db.Query("delete from higher_level_category where id = $1", id)
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
