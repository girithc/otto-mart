package store

import (
	"database/sql"
	"fmt"
	"time"
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

func (s *PostgresStore) CreatePacker(phone string) (*Packer, error) {
	// Query to check if a packer already exists with the given phone number
	checkQuery := `SELECT id, name, phone, address, created_at FROM packer WHERE phone = $1`

	var existingPacker Packer
	err := s.db.QueryRow(checkQuery, phone).Scan(&existingPacker.ID, &existingPacker.Name, &existingPacker.Phone, &existingPacker.Address, &existingPacker.CreatedAt)

	// If a packer is found, return their details
	if err == nil {
		return &existingPacker, nil
	}

	// If no existing packer was found, create a new one
	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing packer: %w", err)
	}

	// SQL query to insert a new packer and return its details
	insertQuery := `
        INSERT INTO packer (name, phone, address)
        VALUES ('', $1, '')
        RETURNING id, name, phone, address, created_at;
    `

	var newPacker Packer
	err = s.db.QueryRow(insertQuery, phone).Scan(&newPacker.ID, &newPacker.Name, &newPacker.Phone, &newPacker.Address, &newPacker.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("error creating new packer: %w %s", err, phone)
	}

	return &newPacker, nil
}

// Packer represents the structure of a packer in the database
type Packer struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Phone     string    `json:"phone"`
	Address   string    `json:"address"`
	CreatedAt time.Time `json:"created_at"`
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
	var orderId int
	statusCheckQuery := `SELECT id, order_status FROM sales_order WHERE cart_id = $1;`
	err = s.db.QueryRow(statusCheckQuery, cart_id).Scan(&orderId, &currentStatus)
	if err != nil {
		return fmt.Errorf("error checking order status: %w", err)
	}
	if currentStatus != "accepted" {
		return fmt.Errorf("order cannot be packed; current status: %s", currentStatus)
	}

	// Then, update the order status to 'packed'
	packOrderQuery := `
    UPDATE sales_order
    SET order_status = 'packed', packer_id = $1
    WHERE cart_id = $2 AND id = $3;`

	_, err = s.db.Exec(packOrderQuery, packerID, cart_id, orderId)
	if err != nil {
		return fmt.Errorf("error updating order status to 'packed': %w", err)
	}

	return nil
}
