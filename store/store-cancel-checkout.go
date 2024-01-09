package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) Cancel_Checkout(cart_id int, sign string) error {
	fmt.Println("Entered Cancel_Checkout")

	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %w", err)
	}

	fmt.Println("Entered EndCartLock")
	alreadyCancelled, cartUnlock, err := s.EndCartLock(tx, cart_id, sign)
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

		err = s.DeleteTransaction(tx, cart_id)
		if err != nil {
			tx.Rollback()
			return fmt.Errorf("error deleting transaction: %w", err)
		}
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
	_, err := tx.Exec(`WITH quantities AS (
        SELECT item_id, quantity 
        FROM cart_item 
        WHERE cart_id = $1
    )
    UPDATE item_store 
    SET stock_quantity = stock_quantity + quantities.quantity, 
        locked_quantity = locked_quantity - quantities.quantity
    FROM quantities 
    WHERE item_store.id = quantities.item_id;
    `, cart_id)
	return err
}

func (s *PostgresStore) EndCartLock(tx *sql.Tx, cartId int, sign string) (string, bool, error) {
	// Update the cart_lock record
	query := `UPDATE cart_lock SET completed = 'ended', last_updated = CURRENT_TIMESTAMP WHERE cart_id = $1 AND completed = 'started' AND sign = $2`
	res, err := tx.Exec(query, cartId, sign)
	if err != nil {
		tx.Rollback() // Rollback in case of any error
		print(err)
		return "", false, fmt.Errorf("error updating cart_lock table: %w", err)
	}

	// Check if any rows were affected
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		tx.Rollback()
		print(err)
		return "", false, fmt.Errorf("error getting rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return "done", false, nil
	}

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
