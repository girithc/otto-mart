package store

import (
	"database/sql"

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
