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
			transaction_id VARCHAR(35) DEFAULT '',
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

	// Add transaction_id column to the existing table
	alterQuery := `
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = 'transaction' AND column_name = 'transaction_id'
            ) THEN
                ALTER TABLE transaction
                ADD COLUMN transaction_id VARCHAR(35) DEFAULT '';
            END IF;
        END
        $$;`

	_, err = tx.Exec(alterQuery)
	if err != nil {
		return fmt.Errorf("error altering transaction table to add transaction_id: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateTransaction(tx *sql.Tx, cart_id int) (string, error) {
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
	err := tx.QueryRow(query, cart_id).Scan(&cartID, &merchantUserID, &amount)
	if err != nil {
		return "", fmt.Errorf("error %d", err)
	}

	// Define the transaction status (e.g., 'pending', 'completed', etc.)
	status := "pending" // or any appropriate status

	insertQuery := `INSERT INTO transaction (merchant_user_id, cart_id, merchant_transaction_id, amount, status)
                VALUES ($1, $2, $3, $4, $5)`
	_, err = tx.Exec(insertQuery, merchantUserID, cartID, merchantTransactionID, amount, status)

	if err != nil {
		// Check if the error is a pq.Error
		if pqErr, ok := err.(*pq.Error); ok {
			// Check if the error code is for a unique violation
			if pqErr.Code == "23505" {
				// Handle the unique constraint violation
				return "", fmt.Errorf("unique constraint violation: %v", err)
			}
		}
		// Handle other errors
		return "", fmt.Errorf("error %d", err)
	}

	return merchantTransactionID, nil
}

// TransactionDetails represents the details of the transaction.
type TransactionDetails struct {
	Status                string
	ResponseCode          string
	PaymentDetails        interface{}
	PaymentMethod         string
	MerchantID            string
	PaymentGatewayName    string
	MerchantTransactionID string
	TransactionID         string
}

// CompleteTransaction updates a transaction and returns the updated details.
func (s *PostgresStore) CompleteTransaction(tx *sql.Tx, paymentDetails TransactionDetails) (bool, error) {
	// Prepare and execute the SQL update query
	updateQuery := `
    UPDATE transaction
    SET status = $1, 
        response_code = $2,
        payment_details = $3,
        payment_method = $4,
        merchant_id = $5,
        payment_gateway_name = $6,
		transaction_id = $7
    WHERE merchant_transaction_id = $8`

	if _, err := tx.Exec(updateQuery, paymentDetails.Status, paymentDetails.ResponseCode,
		paymentDetails.PaymentDetails, paymentDetails.PaymentMethod, paymentDetails.MerchantID,
		paymentDetails.PaymentGatewayName, paymentDetails.TransactionID, paymentDetails.MerchantTransactionID); err != nil {
		fmt.Printf("Error updating transaction record: %v\n", err)
		return false, err
	}

	return true, nil
}

func (s *PostgresStore) DeleteTransaction(tx *sql.Tx, cartID int, merchantTransactionID string) error {
	// Delete transactions related to the fetched sales_order_id
	deleteQuery := `DELETE FROM transaction WHERE cart_id = $1 AND status = 'pending' AND merchant_transaction_id  = $2`
	_, err := tx.Exec(deleteQuery, cartID, merchantTransactionID)
	if err != nil {
		return fmt.Errorf("error deleting transaction for cartID %d: %w", cartID, err)
	}

	return nil
}
