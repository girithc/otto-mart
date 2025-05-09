package store

import (
	"database/sql"
	"fmt"
	"strings"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCartLockTable(tx *sql.Tx) error {
	fmt.Println("Entered CreateCartLockTable")

	// Check and create lock_type_enum if it doesn't exist
	lockTypeEnum := "lock_type_enum"
	if err := s.checkAndCreateEnum(tx, lockTypeEnum, []string{"lock-stock", "lock-stock-pay", "pay-verify", "paid"}); err != nil {
		return err
	}

	// Check and create completed_status_enum if it doesn't exist
	completedStatusEnum := "completed_status_enum"
	if err := s.checkAndCreateEnum(tx, completedStatusEnum, []string{"started", "success", "ended"}); err != nil {
		return err
	}

	// Create or modify the cart_lock table
	createTableQuery := `
	CREATE TABLE IF NOT EXISTS cart_lock (
		id SERIAL PRIMARY KEY,
		cart_id INT,
		lock_type lock_type_enum NOT NULL,
		completed completed_status_enum NOT NULL DEFAULT 'started',
		sign UUID DEFAULT gen_random_uuid(),
		lock_timeout TIMESTAMP NULL,  
		last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := tx.Exec(createTableQuery)
	if err != nil {
		return fmt.Errorf("error creating cart_lock table: %w", err)
	}

	// Additional check to add the 'sign' column if it's missing in an existing table
	var exists bool
	checkColumnQuery := `SELECT EXISTS (
                            SELECT FROM information_schema.columns 
                            WHERE table_schema = 'public' 
                            AND table_name = 'cart_lock' 
                            AND column_name = 'sign'
                        )`
	err = tx.QueryRow(checkColumnQuery).Scan(&exists)
	if err != nil {
		return fmt.Errorf("error checking existence of 'sign' column in cart_lock table: %w", err)
	}

	if !exists {
		alterTableQuery := `ALTER TABLE cart_lock ADD COLUMN sign UUID DEFAULT gen_random_uuid()`
		_, err = tx.Exec(alterTableQuery)
		if err != nil {
			return fmt.Errorf("error adding 'sign' column to cart_lock table: %w", err)
		}
		fmt.Println("'sign' column added to cart_lock table")
	}

	fmt.Println("Exiting CreateCartLockTable")
	return nil
}

func (s *PostgresStore) checkAndCreateEnum(tx *sql.Tx, enumName string, enumValues []string) error {
	// Check if the enum type already exists
	var exists bool
	checkQuery := `SELECT EXISTS (SELECT 1 FROM pg_type WHERE typname = $1)`
	err := tx.QueryRow(checkQuery, enumName).Scan(&exists)
	if err != nil {
		return fmt.Errorf("error checking for existence of enum %s: %w", enumName, err)
	}

	// Create the enum type if it doesn't exist
	if !exists {
		values := "'" + strings.Join(enumValues, "', '") + "'"
		createEnumQuery := fmt.Sprintf("CREATE TYPE %s AS ENUM (%s)", enumName, values)
		_, err := tx.Exec(createEnumQuery)
		if err != nil {
			return fmt.Errorf("error creating enum type %s: %w", enumName, err)
		}
	}

	return nil
}
