package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreateTransactionTable(tx *sql.Tx) error {
	query := `
        CREATE TABLE IF NOT EXISTS transaction (
            id SERIAL PRIMARY KEY,
            transaction_id VARCHAR(50) NOT NULL UNIQUE,
            merchant_transaction_id VARCHAR(35) REFERENCES Sales_order(merchant_transaction_id) ON DELETE CASCADE,
            merchant_id VARCHAR(38) NOT NULL CHECK (
                CHAR_LENGTH(merchant_id) <= 38
            ),
			merchant_user_id VARCHAR(36) REFERENCES Customer(merchant_user_id) ON DELETE CASCADE,
            sales_order_id INT REFERENCES sales_order(id) ON DELETE CASCADE,
            customer_id INT REFERENCES customer(id) ON DELETE CASCADE,
            payment_method VARCHAR(20) NOT NULL,
            amount INT CHECK (amount > 0),
            transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(20) NOT NULL,
            response_code VARCHAR(20) NOT NULL,
            payment_gateway_name VARCHAR(50) NOT NULL,
            payment_details JSONB
        )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating transaction table: %w", err)
	}

	return err
}
