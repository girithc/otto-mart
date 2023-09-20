package store

import (
	"context"
	"database/sql"
	"fmt"
	"pronto-go/types"
	"time"
)

func (s *PostgresStore) Checkout_Items(cart_id int) error {
    fmt.Println("Entered Checkout_Items")

    // Begin a Transaction 
    tx, err := s.db.Begin()
    if err != nil {
        return err
    }

    // Declare a cursor for fetching items from the cart
    _, err = tx.Exec(`DECLARE cart_cursor CURSOR FOR SELECT item_id, quantity FROM cart_item WHERE cart_id = $1`, cart_id)
    if err != nil {
        tx.Rollback()
        return err
    }

    for {
        fmt.Println("Fetching from cursor")
        checkout_cart_item := &types.Checkout_Cart_Item{}

        // Fetch the next row from the cursor
        err := tx.QueryRow(`FETCH NEXT FROM cart_cursor`).Scan(&checkout_cart_item.Item_Id, &checkout_cart_item.Quantity)
        if err == sql.ErrNoRows {
            break // No more rows left to fetch
        }
        if err != nil {
            tx.Rollback()
            return err
        }

        fmt.Println("Fetched Item - ID:", checkout_cart_item.Item_Id, "Quantity:", checkout_cart_item.Quantity)

        // Try to update stock and locked quantities. This will only work if stock quantity is still available.
        res, err := tx.Exec(`UPDATE item SET stock_quantity = stock_quantity - $1, locked_quantity = locked_quantity + $1 WHERE id = $2 AND stock_quantity >= $1`, checkout_cart_item.Quantity, checkout_cart_item.Item_Id)
        if err != nil {
            tx.Rollback()
            return err
        }

        affectedRows, err := res.RowsAffected()
        if err != nil {
            tx.Rollback()
            return err
        }

        // If no rows were updated, that means stock was not sufficient.
        if affectedRows == 0 {
            tx.Rollback()
            return fmt.Errorf("not enough stock for item %d", checkout_cart_item.Item_Id)
        }
    }

    // Close the cursor
    _, err = tx.Exec(`CLOSE cart_cursor`)
    if err != nil {
        tx.Rollback()
        return err
    }

    // Commit the transaction
    err = tx.Commit()
    if err != nil {
        return err
    }

    // After committing the transaction, start the monitoring goroutine
    go s.MonitorLockedItems(cart_id, 16*time.Second) // Assuming a 45-second timeout

    return nil
}



func (s *PostgresStore) MonitorLockedItems(cart_id int, timeoutDuration time.Duration) {
    // Create a cancelable context
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // Create a channel to signal the completion of the payment check
    doneChan := make(chan bool)
    var isPaid bool
    var err error

    // Start the payment check in a separate goroutine
    go func() {
        isPaid, err = s.IsPaymentDone(ctx, cart_id)
        doneChan <- true 
    }()

    // Wait for the payment check to complete or for the timeout to expire
    select {
    case <-doneChan:
        if err != nil {
            fmt.Printf("Error checking payment status for cart %d: %s\n", cart_id, err)
            return
        }

        if !isPaid {
            err := s.ResetLockedQuantities(cart_id)
            if err != nil {
                fmt.Printf("Error resetting locked quantities for cart %d: %s\n", cart_id, err)
            }
            fmt.Println("Payment Failed! : ResetLockedQuantities")
        }
    case <-time.After(timeoutDuration):
        cancel()  // Cancel the context to stop the IsPaymentDone goroutine
        fmt.Println("Payment check timeout. Resetting quantities...")
        err := s.ResetLockedQuantities(cart_id)
        if err != nil {
            fmt.Printf("Error resetting locked quantities for cart %d: %s\n", cart_id, err)
        }
    }
}


// IsPaymentDone checks if the payment has been done for a cart
// You'll need to properly implement this based on your payment system and database schema.
func (s *PostgresStore) IsPaymentDone(ctx context.Context, cart_id int) (bool, error) {
    // Placeholder: Implement logic to check if payment has been completed for the cart.
    // For now, it always returns true. You'll need to query your database or payment system to check the payment status.
    fmt.Println("Started Payment Delay")
    select {
    case <-time.After(14 * time.Second):
        fmt.Println("End Payment Delay")
        return false, nil
    case <-ctx.Done():
        fmt.Println("Payment check was aborted!")
        return false, ctx.Err()
    }
}


// ResetLockedQuantities resets the locked quantities for items in a cart
func (s *PostgresStore) ResetLockedQuantities(cart_id int) error {
    _, err := s.db.Exec(`UPDATE item SET stock_quantity = stock_quantity + (SELECT quantity FROM cart_item WHERE cart_id = $1 AND item_id = item.id), locked_quantity = 0 WHERE id IN (SELECT item_id FROM cart_item WHERE cart_id = $1)`, cart_id)
    return err
}



func scan_Into_Checkout_Cart_Item(rows *sql.Rows) (*types.Checkout_Cart_Item, error) {
	item := new(types.Checkout_Cart_Item)
	err := rows.Scan(
		&item.Item_Id,
        &item.Quantity,

	)

	return item, err
}