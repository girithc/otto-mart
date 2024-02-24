package store

import "database/sql"

func (s *PostgresStore) CreateGSTTable(tx *sql.Tx) error {
	createTableQuery := `CREATE TABLE IF NOT EXISTS gst(
		id SERIAL PRIMARY KEY,
		gst_percent DECIMAL(5,2) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by VARCHAR(255) NOT NULL
	)`
	_, err := tx.Exec(createTableQuery)
	if err != nil {
		return err
	}
	return nil
}
