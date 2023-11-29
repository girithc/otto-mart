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
            sales_order_id INT REFERENCES sales_order(id) ON DELETE CASCADE,
            payment_method VARCHAR(20) DEFAULT '',            
            amount INT CHECK (amount > 0),
            transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(20) DEFAULT '',
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
	merchantTransactionID := uuid.NewString() // This generates a UUID as a string

	// Fetch necessary data from the sales_order and customer tables
	var merchantUserID string
	var salesOrderID int
	var amount int
	query := `SELECT so.id, c.merchant_user_id, so.total
              FROM sales_order so
              JOIN customer c ON so.customer_id = c.id
              WHERE so.cart_id = $1`
	err := s.db.QueryRow(query, cart_id).Scan(&salesOrderID, &merchantUserID, &amount)
	if err != nil {
		return err
	}

	// Define the transaction status (e.g., 'pending', 'completed', etc.)
	status := "pending" // or any appropriate status

	insertQuery := `INSERT INTO transaction (merchant_user_id, sales_order_id, merchant_transaction_id, amount, status)
                VALUES ($1, $2, $3, $4, $5)`
	_, err = s.db.Exec(insertQuery, merchantUserID, salesOrderID, merchantTransactionID, amount, status)

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
		return err
	}

	return nil
}
