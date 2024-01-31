package store

import "database/sql"

func (s *PostgresStore) CreateDeliveryOrderTable(tx *sql.Tx) error {
	query := `
	create table if not exists delivery_order(
		id SERIAL PRIMARY KEY,
		sales_order_id INT REFERENCES sales_order(id) ON DELETE CASCADE,
		delivery_partner_id INT REFERENCES delivery_partner(id) ON DELETE CASCADE,
		order_picked_date TIMESTAMP DEFAULT NULL,
		order_delivered_date TIMESTAMP DEFAULT NULL,
		order_assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		order_accepted_date TIMESTAMP DEFAULT NULL,
		image_url TEXT DEFAULT ''
	)`

	_, err := tx.Exec(query)
	return err
}
