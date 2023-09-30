package store

import (
	"database/sql"
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
	query := `insert into category_higher_level_mapping
	(higher_level_category_id, category_id, created_by) 
	values ($1, $2, $3) returning id, higher_level_category_id, category_id, created_by
	`
	rows, err := s.db.Query(
		query,
		chlm.Higher_Level_Category_ID,
		chlm.Category_ID,
		chlm.Created_By)

	fmt.Println("CheckPoint 1")

	if err != nil {
		return nil, err
	}

	fmt.Println("CheckPoint 2")

	category_higher_level_mappings := []*types.Category_Higher_Level_Mapping{}

	for rows.Next() {
		category_higher_level_mapping, err := scan_Into_Category_Higher_Level_Mapping(rows)
		if err != nil {
			return nil, err
		}
		category_higher_level_mappings = append(category_higher_level_mappings, category_higher_level_mapping)
	}

	fmt.Println("CheckPoint 3")

	return category_higher_level_mappings[0], nil
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
