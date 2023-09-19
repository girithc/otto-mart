package store

import "fmt"


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
            return fmt.Errorf("Not enough stock for item %d", itemID)
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

	return nil
}