package store

import "database/sql"

func (s *PostgresStore) CreateShelfTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS Shelf (
        shelf_id SERIAL PRIMARY KEY,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        horizontal INT NOT NULL,  
		barcode VARCHAR(15) UNIQUE,
        vertical VARCHAR(1) NOT NULL,  
        UNIQUE(store_id, horizontal, vertical)
    );`

	_, err := tx.Exec(query)
	return err
}
