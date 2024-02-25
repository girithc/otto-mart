package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreateTaxTable(tx *sql.Tx) error {
	// SQL query to create the 'tax' table with INTEGER fields and defaults
	createTaxTableQuery := `
    CREATE TABLE IF NOT EXISTS tax (
        id SERIAL PRIMARY KEY,
        sgst INTEGER NOT NULL DEFAULT 0 CHECK (sgst >= 0 AND sgst <= 10000),
        cgst INTEGER NOT NULL DEFAULT 0 CHECK (cgst >= 0 AND cgst <= 10000),
        gst INTEGER NOT NULL DEFAULT 0 CHECK (gst >= 0 AND gst <= 10000),
        cess INTEGER NOT NULL DEFAULT 0 CHECK (cess >= 0 AND cess <= 10000),
        total_tax INTEGER GENERATED ALWAYS AS (gst + cess) STORED
    );`

	_, err := tx.Exec(createTaxTableQuery)
	if err != nil {
		return fmt.Errorf("error creating tax table: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateItemTaxTable(tx *sql.Tx) error {
	// SQL query to create the 'ItemTax' table with a default value for 'hsn_code'
	createItemTaxTableQuery := `
    CREATE TABLE IF NOT EXISTS ItemTax (
        item_id INT NOT NULL,
        tax_id INT NOT NULL,
        hsn_code TEXT NOT NULL DEFAULT '',
        PRIMARY KEY (item_id, tax_id),
        FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE,
        FOREIGN KEY (tax_id) REFERENCES tax(id) ON DELETE CASCADE
    );`

	// Execute the query using the provided transaction
	_, err := tx.Exec(createItemTaxTableQuery)
	if err != nil {
		return fmt.Errorf("error creating ItemTax table: %w", err)
	}

	return nil
}
