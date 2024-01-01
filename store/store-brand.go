package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) CreateBrandTable(tx *sql.Tx) error {
	tableQuery := `
    CREATE TABLE if not exists brand(
		id SERIAL PRIMARY KEY,
		name VARCHAR(255) NOT NULL UNIQUE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)
	`

	_, err := tx.Exec(tableQuery)
	if err != nil {
		return err
	}

	return nil
}

func (s *PostgresStore) CreateBrand(br *types.Brand) (*types.Brand, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	query := `SELECT id, name, created_at, created_by FROM brand WHERE name = $1`
	existBrand := &types.Brand{}

	err = tx.QueryRow(query, br.Name).Scan(&existBrand.ID, &existBrand.Name, &existBrand.Created_At, &existBrand.Created_By)
	if err == nil {
		return existBrand, nil
	} else if err != sql.ErrNoRows {
		return nil, err
	}

	brandInsertQuery := `
	INSERT INTO brand (name, created_by) 
	VALUES ($1, $2) 
	RETURNING id, name, created_at, created_by`

	result := &types.Brand{}
	err = tx.QueryRow(brandInsertQuery, br.Name, br.Created_By).Scan(&result.ID, &result.Name, &result.Created_At, &result.Created_By)
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

func (s *PostgresStore) GetBrands() ([]*types.Brand, error) {
	print("Entered GetBrands")
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback()

	query := `
	SELECT id, name, created_by, created_at 
	FROM brand
	ORDER BY name
	`

	rows, err := tx.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error querying getbrands: %w", err)
	}

	print("Query executed: ")

	defer rows.Close()

	var brands []*types.Brand

	for rows.Next() {
		brand := &types.Brand{}

		err := rows.Scan(
			&brand.ID,
			&brand.Name,
			&brand.Created_By,
			&brand.Created_At,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning row into brand in getbrands: %w", err)
		}
		print(brand.Name)
		brands = append(brands, brand)
	}

	return brands, nil
}

func (s *PostgresStore) GetBrandsList() ([]Brand, error) {
	var brands []Brand

	query := `SELECT id, name FROM brand`
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error querying brands: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var brand Brand
		if err := rows.Scan(&brand.ID, &brand.Name); err != nil {
			return nil, fmt.Errorf("error scanning brand row: %w", err)
		}
		brands = append(brands, brand)
	}

	// Check for errors from iterating over rows
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating brand rows: %w", err)
	}

	return brands, nil
}

type Brand struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}
