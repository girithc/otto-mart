package store

import (
	"fmt"
	"time"
)


func (s *PostgresStore) Checkout_Items (cart_id int) error {

	//Begin a Transaction 
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	// Fetch all items in the cart
	rows, err := tx.Query(`SELECT item_id, quantity FROM cart_item WHERE cart_id = $1`, cart_id)
	if err != nil {
		return err
	}
	defer rows.Close()
	
	// Check and lock quantities for each item
    for rows.Next() {
        var itemID int
        var quantity int

        err := rows.Scan(&itemID, &quantity)
        if err != nil {
            tx.Rollback()
            return err
        }

        // Lock the current item's quantity
        var stockQuantity int
        err = tx.QueryRow(`SELECT stock_quantity FROM item WHERE id = $1 FOR UPDATE`, itemID).Scan(&stockQuantity)
        if err != nil {
            tx.Rollback()
            return err
        }

        // Check if enough stock is available
        if stockQuantity < quantity {
            tx.Rollback()
            return fmt.Errorf("not enough stock for item %d", itemID)
        }
    }


	// If you reached here, you can safely lock quantities for all items
	rows, err = tx.Query(`SELECT item_id, quantity FROM cart_item WHERE cart_id = $1`, cart_id)
	if err != nil {
		tx.Rollback()
		return err
	}

	for rows.Next() {
		var itemID int
		var quantity int

		err := rows.Scan(&itemID, &quantity)
		if err != nil {
			tx.Rollback()
			return err
		}

		_, err = tx.Exec(`UPDATE items SET stock_quantity = stock_quantity - $1, lock_quantity = lock_quantity + $1 WHERE id = $2`, quantity, itemID)
		if err != nil {
			tx.Rollback()
			return err
		}
	}

	if err := rows.Err(); err != nil {
		tx.Rollback()
		return err
	}

	// Commit the transaction
    err = tx.Commit()
    if err != nil {
        return err
    }

    // After committing the transaction, start the monitoring goroutine
    go s.MonitorLockedItems(cart_id, 45*time.Second) // Assuming a 15-minute timeout

    return nil
}

// MonitorLockedItems checks the payment status after a specified timeout
func (s *PostgresStore) MonitorLockedItems(cart_id int, timeoutDuration time.Duration) {
    <-time.After(timeoutDuration)

    isPaid, err := s.IsPaymentDone(cart_id)
    if err != nil {
        // Log the error and return
        fmt.Printf("Error checking payment status for cart %d: %s\n", cart_id, err)
        return
    }

    if !isPaid {
        err := s.ResetLockedQuantities(cart_id)
        if err != nil {
            // Log the error and return
            fmt.Printf("Error resetting locked quantities for cart %d: %s\n", cart_id, err)
        }
    }
}

// IsPaymentDone checks if the payment has been done for a cart
// You'll need to properly implement this based on your payment system and database schema.
func (s *PostgresStore) IsPaymentDone(cart_id int) (bool, error) {
    // Placeholder: Implement logic to check if payment has been completed for the cart.
    // For now, it always returns true. You'll need to query your database or payment system to check the payment status.
   
	// Introducing a delay of 5 seconds
    time.Sleep(5 * time.Second)

	return true, nil
}

// ResetLockedQuantities resets the locked quantities for items in a cart
func (s *PostgresStore) ResetLockedQuantities(cart_id int) error {
    _, err := s.db.Exec(`UPDATE items SET stock_quantity = stock_quantity + (SELECT quantity FROM cart_item WHERE cart_id = $1 AND item_id = items.id), lock_quantity = 0 WHERE id IN (SELECT item_id FROM cart_item WHERE cart_id = $1)`, cart_id)
    return err
}
