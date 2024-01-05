package store

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/girithc/pronto-go/types"
)

// helper functions start
func (s *PostgresStore) getCartItems(cartId int) ([]*types.Checkout_Cart_Item, error) {
	query := `SELECT item_id, quantity FROM cart_item WHERE cart_id = $1 ORDER BY item_id` // Ordered by item_id to reduce deadlock chances
	rows, err := s.db.Query(query, cartId)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cartItems []*types.Checkout_Cart_Item
	for rows.Next() {
		checkout_cart_item := &types.Checkout_Cart_Item{}
		if err := rows.Scan(&checkout_cart_item.Item_Id, &checkout_cart_item.Quantity); err != nil {
			return nil, err
		}
		cartItems = append(cartItems, checkout_cart_item)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return cartItems, nil
}

func (s *PostgresStore) lockItems(cartItems []*types.Checkout_Cart_Item, tx *sql.Tx) (bool, error) {
	for _, checkout_cart_item := range cartItems {
		fmt.Printf("Item ID: %d Quantity: %d \n", checkout_cart_item.Item_Id, checkout_cart_item.Quantity)

		res, err := tx.Exec(`UPDATE item_store SET stock_quantity = stock_quantity - $1, locked_quantity = locked_quantity + $1 WHERE id = $2 AND stock_quantity >= $1`, checkout_cart_item.Quantity, checkout_cart_item.Item_Id)
		if err != nil {
			return false, fmt.Errorf("error update item %d %d", checkout_cart_item.Item_Id, err)
		}

		affectedRows, err := res.RowsAffected()
		if err != nil {
			return false, fmt.Errorf("error for item id %d %d", checkout_cart_item.Item_Id, err)
		}

		if affectedRows == 0 {
			return false, fmt.Errorf("not enough stock for item %d %d", checkout_cart_item.Item_Id, err)
		}
	}
	return true, nil
}

func (s *PostgresStore) cartLockStock(cartId int, tx *sql.Tx) error {
	// Insert a record into the cart_lock table
	lockType := "lock-stock"
	expiresAt := time.Now().Add(1 * time.Minute) // 1 minute from now
	_, err := tx.Exec(`INSERT INTO cart_lock (cart_id, lock_type, expires_at) VALUES ($1, $2, $3)`, cartId, lockType, expiresAt)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error inserting lock record for cart %d: %v", cartId, err)
	}

	return nil
}

// /helper functions end

func (s *PostgresStore) LockStock(cart_id int) (bool, error) {
	cartItems, err := s.getCartItems(cart_id)
	if err != nil {
		return false, err
	}

	// Transaction starts
	tx, err := s.db.Begin()
	if err != nil {
		return false, err
	}

	// Deferred rollback in case of any error during the transaction
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	areItemsLocked, err := s.lockItems(cartItems, tx)
	if err != nil {
		return areItemsLocked, err
	}

	err = s.cartLockStock(cart_id, tx)
	if err != nil {
		return false, err
	}

	err = tx.Commit()
	if err != nil {
		return false, fmt.Errorf("error in committing transaction: %v", err)
	}

	// Transaction ends

	err = s.CreateTransaction(cart_id)
	if err != nil {
		fmt.Print("Error in Creating Transaction: ", err)
		return false, err
	}

	return true, nil
}

func (s *PostgresStore) PayStock(cart_id int) (bool, error) {
	var credit bool
	if cancel, exists := s.cancelFuncs[cart_id]; exists {
		if _, prepay := s.paymentStatus[cart_id]; prepay {
			credit = true
		}
		s.paymentStatus[cart_id] = true
		cancel()
	} else {
		// Timeout Try Locking Quantities again
		// isLocked, err := s.LockStock(cart_id)
		return false, fmt.Errorf("timeout no active timer found for cart id %d", cart_id)
	}

	fmt.Println("Step 1. Payment is successful!")

	var storeID sql.NullInt64

	tx, err := s.db.Begin()
	if err != nil {
		return false, err
	}

	query := `SELECT item_id, quantity FROM cart_item WHERE cart_id = $1 ORDER BY item_id` // Ordered by item_id to reduce deadlock chances
	rows, err := tx.Query(query, cart_id)
	if err != nil {
		return true, err
	}
	defer rows.Close()

	var cartItems []*types.Checkout_Cart_Item
	for rows.Next() {
		checkout_cart_item := &types.Checkout_Cart_Item{}
		if err := rows.Scan(&checkout_cart_item.Item_Id, &checkout_cart_item.Quantity); err != nil {
			return true, err
		}
		cartItems = append(cartItems, checkout_cart_item)
	}
	if err = rows.Err(); err != nil {
		return true, err
	}

	// Existing query to fetch customer_id, store_id, and address from shopping_cart
	var customerID sql.NullInt64
	err = tx.QueryRow(`SELECT customer_id, store_id FROM shopping_cart WHERE id = $1`, cart_id).Scan(&customerID, &storeID)
	if err != nil {
		return true, fmt.Errorf("failed to fetch shopping cart data for cart %d: %s", cart_id, err)
	}

	// Check if customerID is valid
	if !customerID.Valid {
		// Handle the case where customerID is NULL or invalid
		return true, fmt.Errorf("customer ID is null or invalid for cart %d", cart_id)
	}

	// New query to get the default address ID for the customer
	var defaultAddressID int
	err = tx.QueryRow(`SELECT id FROM address WHERE customer_id = $1 AND is_default = TRUE`, customerID.Int64).Scan(&defaultAddressID)
	if err != nil {
		// Handle the error, for example, no default address found or query failed
		return true, fmt.Errorf("failed to fetch default address for customer %d: %s", customerID.Int64, err)
	}

	// Continue with your logic, now having defaultAddressID

	var paymentType string
	if credit {
		paymentType = "credit card"
	} else {
		paymentType = "cash"
	}

	var transactionID int
	err = tx.QueryRow(`SELECT id FROM transaction WHERE cart_id = $1 `, cart_id).Scan(&transactionID)
	if err != nil {
		// Handle the error, for example, no default address found or query failed
		return true, fmt.Errorf("failed to transaction_id for cart_id %d: %s", cart_id, err)
	}

	_, err = tx.Exec(`
		INSERT INTO sales_order ( cart_id, store_id, customer_id, address_id, payment_type, transaction_id)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, cart_id, 1, customerID, defaultAddressID, paymentType, transactionID)
	if err != nil {
		return true, fmt.Errorf("error creating sales_order for cart %d: %s", cart_id, err)
	}

	for _, checkout_cart_item := range cartItems {
		fmt.Printf("Item ID: %d Quantity: %d \n", checkout_cart_item.Item_Id, checkout_cart_item.Quantity)

		res, err := tx.Exec(`UPDATE item_store SET locked_quantity = locked_quantity - $1 WHERE id = $2 AND locked_quantity >= $1`, checkout_cart_item.Quantity, checkout_cart_item.Item_Id)
		if err != nil {
			return true, err
		}

		affectedRows, err := res.RowsAffected()
		if err != nil {
			return true, err
		}

		if affectedRows == 0 {
			return true, fmt.Errorf("not enough stock for item %d", checkout_cart_item.Item_Id)
		}
	}

	_, err = tx.Exec(`UPDATE shopping_cart SET active = false WHERE id = $1`, cart_id)
	if err != nil {
		return true, fmt.Errorf("error setting cart to inactive for cart %d: %s", cart_id, err)
	}

	err = tx.Commit()
	if err != nil {
		return true, err
	}

	query = `insert into shopping_cart
			(customer_id, active) 
			values ($1, $2) returning id, customer_id, active, created_at
			`
	_, err = s.db.Query(
		query,
		customerID,
		true,
	)
	if err != nil {
		return true, err
	}

	deliveryPartnerID, err := s.getNextDeliveryPartner()
	if err != nil {
		return true, fmt.Errorf("error fetching next available delivery partner: %s", err)
	}

	_, err = s.db.Exec(`
		UPDATE sales_order 
		SET delivery_partner_id = $1 
		WHERE cart_id = $2
	`, deliveryPartnerID, cart_id)
	if err != nil {
		return true, fmt.Errorf("error assigning delivery partner for order of cart %d: %s", cart_id, err)
	}

	// Update the delivery partner's last_assigned_time or set their availability to false
	_, err = s.db.Exec(`
		UPDATE delivery_partner 
		SET last_assigned_time = NOW()
		WHERE id = $1
	`, deliveryPartnerID)
	if err != nil {
		return true, fmt.Errorf("error updating delivery partner details: %s", err)
	}

	// If all operations are successful, commit the transaction
	return true, nil
}

/*
func (s *PostgresStore) processPayment(cart_id int) (bool, error) {
	time.Sleep(1 * time.Second)
	return true, nil
}
*/

func (s *PostgresStore) MakeQuantitiesPermanent(cart_id int) error {
	_, err := s.db.Exec(`WITH quantities AS (
        SELECT item_id, quantity 
        FROM cart_item 
        WHERE cart_id = $1
    )
    UPDATE item_store 
    SET locked_quantity = locked_quantity - quantities.quantity
    FROM quantities 
    WHERE item_store.id = quantities.item_id;
    `, cart_id)
	return err
}

func isDeadlockError(err error) bool {
	// This is a simple example. In a real-world scenario, you might want to check the error more thoroughly,
	// maybe using specific error codes or more precise string matching.
	return err.Error() == "deadlock detected"
}

func (s *PostgresStore) MonitorLockedItems(ctx context.Context, tx *sql.Tx, cart_id int, timeoutDuration time.Duration, payment_done bool, cartItems []*types.Checkout_Cart_Item) error {
	fmt.Printf("Entered MonitorLockedItems")
	doneChan := make(chan bool)
	var isPaid bool
	var err error

	go func() {
		isPaid, err = s.IsPaymentDone(ctx, cart_id, payment_done)
		doneChan <- true
	}()

	select {
	case <-doneChan:
		if err != nil {
			return fmt.Errorf("error checking payment status for cart %d: %s", cart_id, err)
		}

		if isPaid {
			fmt.Printf("Payment Successful")

			var customerID, storeID sql.NullInt64
			var address sql.NullString

			err := tx.QueryRowContext(ctx, `SELECT customer_id, store_id, address FROM shopping_cart WHERE id = $1`, cart_id).Scan(&customerID, &storeID, &address)
			if err != nil {
				return fmt.Errorf("failed to fetch shopping cart data for cart %d: %s", cart_id, err)
			}

			_, err = tx.ExecContext(ctx, `
                INSERT INTO sales_order ( cart_id, store_id, customer_id, delivery_address)
                VALUES ($1, $2, $3, $4)
            `, cart_id, 1, customerID, address.String)
			if err != nil {
				return fmt.Errorf("error creating order for cart %d: %s", cart_id, err)
			}

			for _, checkout_cart_item := range cartItems {
				fmt.Printf("Item ID: %d Quantity: %d \n", checkout_cart_item.Item_Id, checkout_cart_item.Quantity)

				res, err := tx.Exec(`UPDATE item_store SET locked_quantity = locked_quantity - $1 WHERE id = $2 AND locked_quantity >= $1`, checkout_cart_item.Quantity, checkout_cart_item.Item_Id)
				if err != nil {
					return err
				}

				affectedRows, err := res.RowsAffected()
				if err != nil {
					return err
				}

				if affectedRows == 0 {
					return fmt.Errorf("not enough stock for item %d", checkout_cart_item.Item_Id)
				}
			}

			_, err = tx.ExecContext(ctx, `UPDATE shopping_cart SET active = false WHERE id = $1`, cart_id)
			if err != nil {
				return fmt.Errorf("error setting cart to inactive for cart %d: %s", cart_id, err)
			}

			query := `insert into shopping_cart
					(customer_id, active) 
					values ($1, $2) returning id, customer_id, active, created_at
					`
			_, err = tx.Query(
				query,
				customerID,
				true,
			)
			if err != nil {
				return err
			}

		} else {
			fmt.Println("Payment was not successful. Resetting quantities...")
			err := s.ResetLockedQuantities(cart_id)
			if err != nil {
				return fmt.Errorf("error resetting locked quantities for cart %d: %s", cart_id, err)
			}
		}

	case <-time.After(timeoutDuration):
		fmt.Println("Payment check timeout. Resetting quantities...")
		err := s.ResetLockedQuantities(cart_id)
		if err != nil {
			return fmt.Errorf("error resetting locked quantities for cart %d: %s", cart_id, err)
		}
	case <-ctx.Done():
		return fmt.Errorf("monitorLockedItems was aborted")
	}

	err = s.PrintItemStoreRecords("after")
	if err != nil {
		return err
	}
	return nil
}

func (s *PostgresStore) IsPaymentDone(ctx context.Context, cart_id int, payment_done bool) (bool, error) {
	fmt.Println("Started Payment Delay")
	select {
	case <-time.After(10 * time.Second):
		fmt.Println("End Payment Delay")
		return payment_done, nil
	case <-ctx.Done():
		fmt.Println("Payment check was aborted!")
		return false, ctx.Err()
	}
}

func (s *PostgresStore) PrintItemStoreRecords(state string) error {
	fmt.Printf("When %s", state)
	rows, err := s.db.Query(`SELECT id, item_id, stock_quantity, locked_quantity FROM item_store`)
	if err != nil {
		return err
	}
	defer rows.Close()

	fmt.Println("Item Store Records:")
	fmt.Println("ID\tStock Quantity\tLocked Quantity")
	for rows.Next() {
		var id, itemId int
		var stockQuantity, lockedQuantity int
		if err := rows.Scan(&id, &itemId, &stockQuantity, &lockedQuantity); err != nil {
			return err
		}
		fmt.Printf("%d\t%d\t%d\t\t%d\n", id, itemId, stockQuantity, lockedQuantity)
	}

	return rows.Err()
}
