package store

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCartLockTable(tx *sql.Tx) error {
	fmt.Println("Entered CreateCartLockTable")

	query := `
    CREATE TYPE lock_type_enum AS ENUM ('lock-stock', 'lock-stock-pay');
    CREATE TYPE completed_status_enum AS ENUM ('started', 'success', 'ended');

    CREATE TABLE IF NOT EXISTS cart_lock (
        id SERIAL PRIMARY KEY,
        cart_id INT,
        lock_type lock_type_enum NOT NULL,
        completed completed_status_enum NOT NULL DEFAULT 'started',
        lock_timeout TIMESTAMP,
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating cart_lock table: %w", err)
	}

	fmt.Println("Exiting CreateCartLockTable")
	return nil
}
