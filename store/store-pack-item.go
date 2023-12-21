package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreatePackerItemTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS packer_item (
        id SERIAL PRIMARY KEY,
        item_id INT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        packer_id INT NOT NULL REFERENCES packer(id) ON DELETE CASCADE,
        packing_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        quantity INT NOT NULL CHECK (quantity > 0),
        sales_order_id INT NOT NULL REFERENCES sales_order(id) ON DELETE CASCADE,
        store_id INT NOT NULL REFERENCES store(id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating packer_item table: %w", err)
	}
	return nil
}

func (s *PostgresStore) PackerPackItem(itemId int, packerId int, orderId int) (PackerItemResponse, error) {
	var response PackerItemResponse

	// Retrieve the store_id from the shopping_cart using the order_id
	var storeId int
	storeIdQuery := `SELECT store_id FROM shopping_cart WHERE order_id = $1`
	err := s.db.QueryRow(storeIdQuery, orderId).Scan(&storeId)
	if err != nil {
		if err == sql.ErrNoRows {
			return response, fmt.Errorf("no shopping cart found with order_id %d", orderId)
		}
		return response, fmt.Errorf("error querying store_id: %w", err)
	}

	// Insert a new record into the packer_item table
	insertQuery := `INSERT INTO packer_item (item_id, packer_id, sales_order_id, store_id, quantity) VALUES ($1, $2, $3, $4, $5)`
	_, err = s.db.Exec(insertQuery, itemId, packerId, orderId, storeId, 1) // Assuming default quantity of 1
	if err != nil {
		return response, fmt.Errorf("error inserting into packer_item table: %w", err)
	}

	// Populate and return the response struct
	response = PackerItemResponse{
		ItemID:   itemId,
		PackerID: packerId,
		OrderID:  orderId,
		Success:  true,
	}
	return response, nil
}

type PackerItemResponse struct {
	ItemID   int  `json:"item_id"`
	PackerID int  `json:"packer_id"`
	OrderID  int  `json:"order_id"`
	Success  bool `json:"success"`
}
