package store

import (
	"database/sql"
	"errors"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) Create_Category_Higher_Level_Mapping_Table() error {
	// fmt.Println("Entered CreateCategoryHigherLevelMappingTable")

	query := `create table if not exists category_higher_level_mapping (
		id SERIAL PRIMARY KEY,
		higher_level_category_id INT REFERENCES Higher_Level_Category(id) ON DELETE CASCADE,
		category_id INT REFERENCES Category(id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT,
		UNIQUE(higher_level_category_id, category_id)
	)`

	_, err := s.db.Exec(query)

	// fmt.Println("Exiting CreateCategoryHigherLevelMappingTable")

	return err
}

func (s *PostgresStore) Create_Category_Higher_Level_Mapping(chlm *types.Category_Higher_Level_Mapping) (*types.Category_Higher_Level_Mapping, error) {
	// Start a new transaction.
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // Rollback the transaction in case of failure.

	// Try inserting the new record.
	query := `
        INSERT INTO category_higher_level_mapping
        (higher_level_category_id, category_id, created_by) 
        VALUES ($1, $2, $3) 
        ON CONFLICT (higher_level_category_id, category_id) DO NOTHING 
        RETURNING id, higher_level_category_id, category_id, created_by;
    `
	rows, err := tx.Query(
		query,
		chlm.Higher_Level_Category_ID,
		chlm.Category_ID,
		chlm.Created_By,
	)
	if err != nil {
		return nil, err
	}

	// If we have results from the INSERT query, then the insertion was successful.
	if rows.Next() {
		category_higher_level_mapping, err := scan_Into_Category_Higher_Level_Mapping(rows)
		if err != nil {
			return nil, err
		}
		err = tx.Commit() // Commit the transaction.
		if err != nil {
			return nil, err
		}
		return category_higher_level_mapping, nil
	}

	// If we reached here, it means the record already exists. Fetch and return the existing record.
	existingQuery := `
        SELECT id, higher_level_category_id, category_id, created_by 
        FROM category_higher_level_mapping 
        WHERE higher_level_category_id = $1 AND category_id = $2;
    `
	existingRows, err := tx.Query(existingQuery, chlm.Higher_Level_Category_ID, chlm.Category_ID)
	if err != nil {
		return nil, err
	}

	if existingRows.Next() {
		existingMapping, err := scan_Into_Category_Higher_Level_Mapping(existingRows)
		if err != nil {
			return nil, err
		}
		err = tx.Commit() // Commit the transaction.
		if err != nil {
			return nil, err
		}
		return existingMapping, nil
	}

	return nil, errors.New("expected to find an existing record, but none found")
}

func (s *PostgresStore) Get_Category_Higher_Level_Mappings() ([]*types.Category_Higher_Level_Mapping, error) {
	rows, err := s.db.Query("select id, higher_level_category_id, category_id, created_by from category_higher_level_mapping")
	if err != nil {
		return nil, err
	}

	chlms := []*types.Category_Higher_Level_Mapping{}
	for rows.Next() {
		chlm, err := scan_Into_Category_Higher_Level_Mapping(rows)
		if err != nil {
			return nil, err
		}
		chlms = append(chlms, chlm)
	}

	return chlms, nil
}

func (s *PostgresStore) Get_Category_Higher_Level_Mapping_By_ID(id int) (*types.Category_Higher_Level_Mapping, error) {
	row, err := s.db.Query("select id, higher_level_category_id, category_id, created_by from category_higher_level_mapping where id = $1", id)
	if err != nil {
		return nil, err
	}

	for row.Next() {
		return scan_Into_Category_Higher_Level_Mapping(row)
	}

	return nil, fmt.Errorf("category_higher_level_mapping with id = [%d] not found", id)
}

func (s *PostgresStore) Update_Category_Higher_Level_Mapping(chlm *types.Update_Category_Higher_Level_Mapping) (*types.Update_Category_Higher_Level_Mapping, error) {
	query := `update category_higher_level_mapping
	set 
	higher_level_category_id = $1
	category_id = $2
	where id = $3 
	returning higher_level_category_id, category_id, id`

	rows, err := s.db.Query(
		query,
		chlm.Higher_Level_Category_ID,
		chlm.Category_ID,
		chlm.ID,
	)
	if err != nil {
		return nil, err
	}

	chlms := []*types.Update_Category_Higher_Level_Mapping{}

	for rows.Next() {
		chlm, err := scan_Into_Update_Category_Higher_Level_Mapping(rows)
		if err != nil {
			return nil, err
		}
		chlms = append(chlms, chlm)
	}

	return chlms[0], nil
}

func (s *PostgresStore) Delete_Category_Higher_Level_Mapping(id int) error {
	_, err := s.db.Query("delete from category_higher_level_mapping where id = $1", id)
	return err
}

func scan_Into_Category_Higher_Level_Mapping(rows *sql.Rows) (*types.Category_Higher_Level_Mapping, error) {
	chlm := new(types.Category_Higher_Level_Mapping)
	err := rows.Scan(
		&chlm.ID,
		&chlm.Higher_Level_Category_ID,
		&chlm.Category_ID,
		&chlm.Created_By,
	)

	return chlm, err
}

func scan_Into_Update_Category_Higher_Level_Mapping(rows *sql.Rows) (*types.Update_Category_Higher_Level_Mapping, error) {
	chlm := new(types.Update_Category_Higher_Level_Mapping)
	error := rows.Scan(
		&chlm.Higher_Level_Category_ID,
		&chlm.Category_ID,
		&chlm.ID,
	)
	return chlm, error
}
