package store

import (
	"context"
	"database/sql"
	"fmt"
	"math/rand"
	"time"

	"github.com/girithc/pronto-go/types"
)

const maxRetries = 3

func (s *PostgresStore) Checkout_Items(cart_id int, payment_done bool) error {
	for i := 0; i < maxRetries; i++ {
		err := s.tryCheckout(cart_id, payment_done)
		if err != nil {
			// If it's a deadlock, wait and retry
			if isDeadlockError(err) {
				time.Sleep(time.Millisecond * time.Duration(rand.Intn(100)))
				continue
			}
			// If it's another type of error, return immediately
			return err
		}
		// If successful, break out of the loop
		break
	}
	return nil
}

func (s *PostgresStore) LockStock(cart_id int) (bool, error) {
	query := `SELECT item_id, quantity FROM cart_item WHERE cart_id = $1 ORDER BY item_id` // Ordered by item_id to reduce deadlock chances
	rows, err := s.db.Query(query, cart_id)
	if err != nil {
		return false, err
	}
	defer rows.Close()

	var cartItems []*types.Checkout_Cart_Item
	for rows.Next() {
		checkout_cart_item := &types.Checkout_Cart_Item{}
		if err := rows.Scan(&checkout_cart_item.Item_Id, &checkout_cart_item.Quantity); err != nil {
			return false, err
		}
		cartItems = append(cartItems, checkout_cart_item)
	}
	if err = rows.Err(); err != nil {
		return false, err
	}

	tx, err := s.db.Begin()
	if err != nil {
		return false, err
	}

	for _, checkout_cart_item := range cartItems {
		fmt.Printf("Item ID: %d Quantity: %d \n", checkout_cart_item.Item_Id, checkout_cart_item.Quantity)

		res, err := tx.Exec(`UPDATE item_store SET stock_quantity = stock_quantity - $1, locked_quantity = locked_quantity + $1 WHERE id = $2 AND stock_quantity >= $1`, checkout_cart_item.Quantity, checkout_cart_item.Item_Id)
		if err != nil {
			return false, err
		}

		affectedRows, err := res.RowsAffected()
		if err != nil {
			return false, err
		}

		if affectedRows == 0 {
			return false, fmt.Errorf("not enough stock for item %d", checkout_cart_item.Item_Id)
		}
	}

	err = tx.Commit()
	if err != nil {
		return false, err
	}

	// Start a timer
	ctx, cancel := context.WithTimeout(context.Background(), 35*time.Second) // Set your desired timeout duration

	// Store the cancel function
	s.cancelFuncs[cart_id] = cancel

	// Launch a goroutine to await the context's completion or timeout
	go func() {
		<-ctx.Done()
		if ctx.Err() == context.DeadlineExceeded {
			// Timeout exceeded, reset quantities
			fmt.Println("Payment was not made in time. Resetting quantities...")
			s.ResetLockedQuantities(cart_id)
			delete(s.cancelFuncs, cart_id)

		} else if _, exists := s.cancelFuncs[cart_id]; exists {
			// Payment was attempted but was unsuccessful
			fmt.Println("Payment In Process")
			delete(s.cancelFuncs, cart_id)
		} else {
			// Unkown Error
			fmt.Println("Unknown Error")
			s.ResetLockedQuantities(cart_id)
		}
	}()

	s.PrintItemStoreRecords("Updated Records ")

	return true, nil
}

func (s *PostgresStore) PayStock(cart_id int) (bool, error) {
	if cancel, exists := s.cancelFuncs[cart_id]; exists {
		cancel()
	} else {
		// Timeout Try Locking Quantities again
		isLocked, err := s.LockStock(cart_id)
		if err != nil {
			return false, fmt.Errorf("error locking quantities for cart id %d", cart_id)
		}
		if !isLocked {
			return false, fmt.Errorf("no active timer found for cart id %d", cart_id)
		}
	}

	print("Checkpoint Paystock")

	timeoutDuration := 10 * time.Second
	ctx, cancel := context.WithTimeout(context.Background(), timeoutDuration) // Set your desired timeout duration

	// Store the cancel function
	s.cancelFuncs[cart_id] = cancel

	doneChan := make(chan bool)
	var isPaymentSuccessful bool
	var err error

	go func() {
		isPaymentSuccessful, err = s.processPayment(cart_id)
		doneChan <- true
	}()

	select {
	case <-doneChan:
		if err != nil {
			s.ResetLockedQuantities(cart_id)
			if cancel, exists := s.cancelFuncs[cart_id]; exists {
				cancel()
				delete(s.cancelFuncs, cart_id)
			}

			return false, fmt.Errorf("error checking payment status for cart %d: %s", cart_id, err)
		}

		if isPaymentSuccessful {

			fmt.Println("Payment was successful!")
			if cancel, exists := s.cancelFuncs[cart_id]; exists {
				cancel()
				delete(s.cancelFuncs, cart_id)
			}
			return true, nil
		} else {
			fmt.Println("Payment was not successful!")
			err := s.ResetLockedQuantities(cart_id)
			if cancel, exists := s.cancelFuncs[cart_id]; exists {
				cancel()
				delete(s.cancelFuncs, cart_id)
			}
			if err != nil {
				return false, fmt.Errorf("error resetting quantities")
			}
			return false, nil
		}
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			// Timeout exceeded, reset quantities
			fmt.Println("Payment was not made in time. Resetting quantities...")
			err := s.ResetLockedQuantities(cart_id)
			delete(s.cancelFuncs, cart_id)
			if err != nil {
				return false, fmt.Errorf("error resetting locked quantities for cart %d: %s", cart_id, err)
			}
		} else {
			fmt.Println("Timeout. Unknown Error")

			delete(s.cancelFuncs, cart_id)
			err := s.ResetLockedQuantities(cart_id)
			if err != nil {
				return false, fmt.Errorf("error resetting locked quantities for cart %d: %s", cart_id, err)
			}
		}
	}
	return true, nil
}

func (s *PostgresStore) processPayment(cart_id int) (bool, error) {
	time.Sleep(1 * time.Second)
	return false, nil
}

func (s *PostgresStore) ResetLockedQuantities(cart_id int) error {
	_, err := s.db.Exec(`WITH quantities AS (
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

func (s *PostgresStore) tryCheckout(cart_id int, payment_done bool) error {
	fmt.Printf("Entered Checkout_Items. Payment: %t", payment_done)

	// Start the database transaction

	query := `SELECT item_id, quantity FROM cart_item WHERE cart_id = $1 ORDER BY item_id` // Ordered by item_id to reduce deadlock chances
	rows, err := s.db.Query(query, cart_id)
	if err != nil {
		return err
	}
	defer rows.Close()

	var cartItems []*types.Checkout_Cart_Item
	for rows.Next() {
		checkout_cart_item := &types.Checkout_Cart_Item{}
		if err := rows.Scan(&checkout_cart_item.Item_Id, &checkout_cart_item.Quantity); err != nil {
			return err
		}
		cartItems = append(cartItems, checkout_cart_item)
	}
	if err = rows.Err(); err != nil {
		return err
	}

	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	for _, checkout_cart_item := range cartItems {
		fmt.Printf("Item ID: %d Quantity: %d \n", checkout_cart_item.Item_Id, checkout_cart_item.Quantity)

		res, err := tx.Exec(`UPDATE item_store SET stock_quantity = stock_quantity - $1, locked_quantity = locked_quantity + $1 WHERE id = $2 AND stock_quantity >= $1`, checkout_cart_item.Quantity, checkout_cart_item.Item_Id)
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

	err = tx.Commit()
	if err != nil {
		return err
	}

	s.PrintItemStoreRecords("Updated Records ")

	tx, err = s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback() // Rollback the transaction in case of any error

	ctx := context.Background()

	err = s.MonitorLockedItems(ctx, tx, cart_id, 15*time.Second, payment_done, cartItems)
	if err != nil {
		return err
	}

	err = tx.Commit()
	if err != nil {
		return err
	}

	tx, err = s.db.Begin()
	if err != nil {
		return err
	}

	deliveryPartnerID, err := s.getNextDeliveryPartner()
	if err != nil {
		return fmt.Errorf("error fetching next available delivery partner: %s", err)
	}

	_, err = tx.ExecContext(ctx, `
				UPDATE sales_order 
				SET delivery_partner_id = $1 
				WHERE cart_id = $2
			`, deliveryPartnerID, cart_id)
	if err != nil {
		return fmt.Errorf("error assigning delivery partner for order of cart %d: %s", cart_id, err)
	}

	// Update the delivery partner's last_assigned_time or set their availability to false
	_, err = tx.ExecContext(ctx, `
				UPDATE delivery_partner 
				SET last_assigned_time = NOW()
				WHERE id = $1
			`, deliveryPartnerID)
	if err != nil {
		return fmt.Errorf("error updating delivery partner details: %s", err)
	}

	// If all operations are successful, commit the transaction
	return tx.Commit()
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
