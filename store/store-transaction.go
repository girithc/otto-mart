package store

import (
	"database/sql"
	"fmt"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

func (s *PostgresStore) CreateTransactionTable(tx *sql.Tx) error {
	query := `

        CREATE TABLE IF NOT EXISTS transaction (
            id SERIAL PRIMARY KEY,
            merchant_transaction_id VARCHAR(35) NOT NULL CHECK (
                CHAR_LENGTH(merchant_transaction_id) <= 35 AND 
                merchant_transaction_id ~ '^[A-Za-z0-9_-]*$'
            ),
            merchant_id VARCHAR(38) DEFAULT '' CHECK (
                CHAR_LENGTH(merchant_id) <= 38
            ),
            merchant_user_id VARCHAR(36) REFERENCES Customer(merchant_user_id) ON DELETE CASCADE,
            cart_id INT REFERENCES shopping_cart(id) ON DELETE CASCADE,
            payment_method VARCHAR(20) DEFAULT '',            
            amount INT CHECK (amount > 0),
            transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(20) DEFAULT 'pending',
            response_code VARCHAR(20) DEFAULT '',
            payment_gateway_name VARCHAR(50) DEFAULT '',
            payment_details JSONB
        )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating transaction table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateTransaction(cart_id int) error {
	// Generate a unique merchant transaction ID
	fmt.Println("Entered Create Transaction")
	merchantTransactionID := uuid.NewString()
	if len(merchantTransactionID) > 35 {
		merchantTransactionID = merchantTransactionID[:35]
	}
	// This generates a UUID as a string

	// Fetch necessary data from the sales_order and customer tables
	var merchantUserID string
	var cartID int
	var amount int
	query := `SELECT sc.id, c.merchant_user_id, sc.subtotal
              FROM shopping_cart sc
              JOIN customer c ON sc.customer_id = c.id
              WHERE sc.id = $1`
	err := s.db.QueryRow(query, cart_id).Scan(&cartID, &merchantUserID, &amount)
	if err != nil {
		return fmt.Errorf("error %d", err)
	}

	// Define the transaction status (e.g., 'pending', 'completed', etc.)
	status := "pending" // or any appropriate status

	insertQuery := `INSERT INTO transaction (merchant_user_id, cart_id, merchant_transaction_id, amount, status)
                VALUES ($1, $2, $3, $4, $5)`
	_, err = s.db.Exec(insertQuery, merchantUserID, cartID, merchantTransactionID, amount, status)

	if err != nil {
		// Check if the error is a pq.Error
		if pqErr, ok := err.(*pq.Error); ok {
			// Check if the error code is for a unique violation
			if pqErr.Code == "23505" {
				// Handle the unique constraint violation
				return fmt.Errorf("unique constraint violation: %v", err)
			}
		}
		// Handle other errors
		return fmt.Errorf("error %d", err)
	}

	return nil
}

func (s *PostgresStore) DeleteTransaction(cart_id int) error {
	// Find the sales_order_id associated with the given cart_id
	var salesOrderID int
	query := `SELECT order_id FROM shopping_cart WHERE cart_id = $1`
	err := s.db.QueryRow(query, cart_id).Scan(&salesOrderID)
	if err != nil {
		// If no sales order is found, handle the error accordingly
		if err == sql.ErrNoRows {
			return fmt.Errorf("no sales order found for cart_id %d", cart_id)
		}
		return fmt.Errorf("error fetching sales order: %w", err)
	}

	// Delete transactions related to the fetched sales_order_id
	deleteQuery := `DELETE FROM transaction WHERE sales_order_id = $1`
	_, err = s.db.Exec(deleteQuery, salesOrderID)
	if err != nil {
		return fmt.Errorf("error deleting transaction for sales_order_id %d: %w", salesOrderID, err)
	}

	return nil
}
