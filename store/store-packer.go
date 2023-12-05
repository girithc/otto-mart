package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreatePackerTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS packer(
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        phone VARCHAR(10) UNIQUE NOT NULL, 
        address TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating packer table: %w", err)
	}
	return nil
}

func (s *PostgresStore) PackerAcceptOrder(cart_id int, phone string) error {
	// First, get the packer_id based on the phone number
	var packerID int
	getPackerIDQuery := `SELECT id FROM packer WHERE phone = $1;`
	err := s.db.QueryRow(getPackerIDQuery, phone).Scan(&packerID)
	if err != nil {
		return fmt.Errorf("error finding packer: %w", err)
	}

	// Check if the current order_status is 'received'
	var currentStatus string
	statusCheckQuery := `SELECT order_status FROM sales_order WHERE cart_id = $1;`
	err = s.db.QueryRow(statusCheckQuery, cart_id).Scan(&currentStatus)
	if err != nil {
		return fmt.Errorf("error checking order status: %w", err)
	}
	if currentStatus != "received" {
		return fmt.Errorf("order status is not 'received'; current status: %s", currentStatus)
	}

	// Then, assign the packer to the order with the given cart_id and update the order status to 'accepted'
	assignPackerQuery := `
    UPDATE sales_order
    SET packer_id = $1, order_status = 'accepted'
    WHERE cart_id = $2 AND packer_id IS NULL;` // Ensuring that no packer is already assigned

	_, err = s.db.Exec(assignPackerQuery, packerID, cart_id)
	if err != nil {
		return fmt.Errorf("error assigning packer to order and updating status: %w", err)
	}

	return nil
}

func (s *PostgresStore) PackerPackOrder(cart_id int, phone string) error {
	// First, get the packer_id based on the phone number
	var packerID int
	getPackerIDQuery := `SELECT id FROM packer WHERE phone = $1;`
	err := s.db.QueryRow(getPackerIDQuery, phone).Scan(&packerID)
	if err != nil {
		return fmt.Errorf("error finding packer: %w", err)
	}

	// Check if the current order_status is 'accepted'
	var currentStatus string
	statusCheckQuery := `SELECT order_status FROM sales_order WHERE cart_id = $1;`
	err = s.db.QueryRow(statusCheckQuery, cart_id).Scan(&currentStatus)
	if err != nil {
		return fmt.Errorf("error checking order status: %w", err)
	}
	if currentStatus != "accepted" {
		return fmt.Errorf("order cannot be packed; current status: %s", currentStatus)
	}

	// Then, update the order status to 'packed'
	packOrderQuery := `
    UPDATE sales_order
    SET order_status = 'packed'
    WHERE cart_id = $1 AND packer_id = $2;`

	_, err = s.db.Exec(packOrderQuery, cart_id, packerID)
	if err != nil {
		return fmt.Errorf("error updating order status to 'packed': %w", err)
	}

	return nil
}
