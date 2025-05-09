package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) Cancel_Checkout(cart_id int, sign string, merchantTransactionID string, lockType string) error {
	fmt.Println("Entered Cancel_Checkout")

	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %w", err)
	}

	fmt.Println("Entered EndCartLock")
	alreadyCancelled, cartUnlock, err := s.EndCartLock(tx, cart_id, sign, lockType)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error ending cart lock: %w", err)
	}

	// Check if the cart lock was already cancelled and gracefully end if it's "done"
	if alreadyCancelled == "done" {
		err = tx.Commit()
		if err != nil {
			return fmt.Errorf("error committing transaction: %w", err)
		}
		fmt.Println("Exiting Cancel_Checkout - Cart Lock already cancelled")
		return nil
	}

	if cartUnlock {
		// Reset the locked quantities
		fmt.Println("Entered ResetLockedQuantities")

		err = s.ResetLockedQuantities(tx, cart_id)
		if err != nil {
			tx.Rollback()
			return fmt.Errorf("error resetting locked quantities: %w", err)
		}

		fmt.Println("Entered DeleteTransaction")

		err = s.DeleteTransaction(tx, cart_id, merchantTransactionID)
		if err != nil {
			tx.Rollback()
			return fmt.Errorf("error deleting transaction: %w", err)
		}

		fmt.Println("Completed DeleteTransaction")
	}

	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("error committing transaction: %w", err)
	}

	fmt.Println("Exiting Cancel_Checkout")
	return nil
}

func (s *PostgresStore) ResetLockedQuantities(tx *sql.Tx, cart_id int) error {
	type ItemUpdate struct {
		ItemID   int
		Quantity int
	}

	// First, retrieve the item_id and quantity from cart_item for the given cart_id
	var updates []ItemUpdate
	query := `SELECT item_id, quantity FROM cart_item WHERE cart_id = $1`
	rows, err := s.db.Query(query, cart_id)
	if err != nil {
		return fmt.Errorf("error querying cart_item table: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var update ItemUpdate
		if err := rows.Scan(&update.ItemID, &update.Quantity); err != nil {
			return fmt.Errorf("error scanning cart_item row: %w", err)
		}
		updates = append(updates, update)
	}

	if err := rows.Err(); err != nil {
		return fmt.Errorf("error iterating over cart_item rows: %w", err)
	}

	// Now, batch update item_store for each item
	for _, update := range updates {
		updateQuery := `
    UPDATE item_store 
    SET stock_quantity = stock_quantity + $1, 
        locked_quantity = locked_quantity - $1
    WHERE item_id = $2 AND locked_quantity >= $1
`
		if _, err := tx.Exec(updateQuery, update.Quantity, update.ItemID); err != nil {
			return fmt.Errorf("error updating item_store table for item_id %d: %w", update.ItemID, err)
		}

	}

	return nil
}

// alreadycancelled, doCartUnlock
func (s *PostgresStore) EndCartLock(tx *sql.Tx, cartId int, sign string, lockType string) (string, bool, error) {
	// First, check if there's an existing sales_order record for the given cartId
	var salesOrderExists bool
	checkQuery := `SELECT EXISTS(SELECT 1 FROM sales_order WHERE cart_id = $1)`
	err := tx.QueryRow(checkQuery, cartId).Scan(&salesOrderExists)
	if err != nil {
		tx.Rollback() // Rollback in case of any error
		return "", false, fmt.Errorf("error checking for existing sales_order record: %w", err)
	}

	// If a sales_order record exists, perform the update on cart_lock and return false
	if salesOrderExists {
		updateQuery := `UPDATE cart_lock SET completed = 'ended', 
        last_updated = CURRENT_TIMESTAMP 
        WHERE cart_id = $1 AND completed = 'started' AND sign = $2 AND lock_type = $3`

		_, err := tx.Exec(updateQuery, cartId, sign, lockType)
		if err != nil {
			tx.Rollback() // Rollback in case of any error
			return "", false, fmt.Errorf("error updating cart_lock table: %w", err)
		}

		// Return 'done' and false, indicating that a sales_order record was found and cart_lock was updated
		return "done", false, nil
	}

	// If no sales_order record exists, proceed with the original logic
	updateQuery := `UPDATE cart_lock SET completed = 'ended', 
    last_updated = CURRENT_TIMESTAMP 
    WHERE cart_id = $1 AND completed = 'started' AND sign = $2 AND lock_type = $3`

	res, err := tx.Exec(updateQuery, cartId, sign, lockType)
	if err != nil {
		tx.Rollback() // Rollback in case of any error
		return "", false, fmt.Errorf("error updating cart_lock table: %w", err)
	}

	// Check if any rows were affected
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		tx.Rollback()
		return "", false, fmt.Errorf("error getting rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return "done", false, nil
	}

	// Return an empty string and true, indicating that no sales_order record was found and cart_lock was updated
	return "", true, nil
}

func (s *PostgresStore) Cancel_PhonePe_Checkout(cart_id int) error {
	cancel, exists := s.cancelFuncs[cart_id]
	if exists {
		delete(s.cancelFuncs, cart_id)
		delete(s.lockExtended, cart_id)
		delete(s.paymentStatus, cart_id)
		cancel() // This cancels the monitoring goroutine and any internal goroutines it started
	} else {
		return fmt.Errorf("error: cart_id %d not found", cart_id)
	}

	return nil
}
