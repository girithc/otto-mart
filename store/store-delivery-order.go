package store

import "database/sql"

func (s *PostgresStore) CreateDeliveryOrderTable(tx *sql.Tx) error {
	// Create the table if it doesn't exist with the new 'amount_collected' field
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
        image_url TEXT DEFAULT '',
        amount_collected INT DEFAULT 0  -- New field with default value of 0
    )`
	if _, err := tx.Exec(createTableQuery); err != nil {
		return err
	}

	// Optionally, add new columns if they don't exist, including 'amount_collected'
	addAmountCollectedQuery := `
    DO $$
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'delivery_order' AND column_name = 'amount_collected') THEN
            ALTER TABLE delivery_order ADD COLUMN amount_collected INT DEFAULT 0;
        END IF;
    END
    $$;`
	if _, err := tx.Exec(addAmountCollectedQuery); err != nil {
		return err
	}

	return nil
}
