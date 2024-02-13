package store

import "database/sql"

func (s *PostgresStore) CreateDeliveryOrderTable(tx *sql.Tx) error {
	// Create the table if it doesn't exist
	createTableQuery := `
    CREATE TABLE IF NOT EXISTS delivery_order(
        id SERIAL PRIMARY KEY,
        sales_order_id INT REFERENCES sales_order(id) ON DELETE CASCADE,
        delivery_partner_id INT REFERENCES delivery_partner(id) ON DELETE CASCADE,
        order_picked_date TIMESTAMP DEFAULT NULL,
        order_delivered_date TIMESTAMP DEFAULT NULL,
        order_assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        order_accepted_date TIMESTAMP DEFAULT NULL,
		order_arrive_date TIMESTAMP DEFAULT NULL, 
        image_url TEXT DEFAULT ''
    )`
	if _, err := tx.Exec(createTableQuery); err != nil {
		return err
	}

	// Check if the order_arrive_date column exists and add it if it doesn't
	addColumnQuery := `
    DO $$
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'delivery_order' AND column_name = 'order_arrive_date') THEN
            ALTER TABLE delivery_order ADD COLUMN order_arrive_date TIMESTAMP DEFAULT NULL;
        END IF;
    END
    $$;`
	if _, err := tx.Exec(addColumnQuery); err != nil {
		return err
	}

	return nil
}
