package store

import "database/sql"

func (s *PostgresStore) CreatePackerShelfTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS Packer_Shelf (
        id SERIAL PRIMARY KEY,
        sales_order_id INT REFERENCES Sales_Order(id) ON DELETE CASCADE,
        packer_id INT REFERENCES Packer(id) ON DELETE CASCADE,
        delivery_shelf_id INT REFERENCES delivery_shelf(id) ON DELETE CASCADE,
        active BOOLEAN NOT NULL DEFAULT true,
        drop_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        pickup_time TIMESTAMP,
        image_url TEXT NULL
    );
    `

	_, err := tx.Exec(query)
	if err != nil {
		return err
	}

	// Alter the table to add image_url column if it doesn't exist
	alterQuery := `
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'packer_shelf' AND column_name = 'image_url'
        ) THEN
            ALTER TABLE Packer_Shelf ADD COLUMN image_url TEXT NULL;
        END IF;
    END
    $$;`

	_, err = tx.Exec(alterQuery)
	return err
}
