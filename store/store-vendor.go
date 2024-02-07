package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreateVendorTable(tx *sql.Tx) error {
	createVendorTableQuery := `
	CREATE TABLE IF NOT EXISTS vendor (
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		address VARCHAR(100) NOT NULL,
		phone VARCHAR(10) NOT NULL,
		email VARCHAR(100) NOT NULL
	);`

	_, err := tx.Exec(createVendorTableQuery)
	if err != nil {
		return fmt.Errorf("error creating vendor table: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateItemVendorTable(tx *sql.Tx) error {
	createItemVendorTableQuery := `
    CREATE TABLE IF NOT EXISTS item_vendor (
        id SERIAL PRIMARY KEY,
        item_id INT NOT NULL,
        vendor_id INT NOT NULL,
        purchase_price DECIMAL(10, 2) NOT NULL,
        purchase_date DATE NOT NULL,
        store_id INT NOT NULL,
        quantity INT NOT NULL CHECK (quantity > 0),
        invoice_number VARCHAR(50),
        is_paid BOOLEAN NOT NULL DEFAULT FALSE,
        paid_date DATE NULL,
        credit_days INT NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by INT,
        FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE,
        FOREIGN KEY (vendor_id) REFERENCES vendor(id) ON DELETE CASCADE,
        FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE CASCADE
    );`

	_, err := tx.Exec(createItemVendorTableQuery)
	if err != nil {
		return fmt.Errorf("error creating item_vendor table: %w", err)
	}

	return nil
}
