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

    ctx, cancel := context.WithCancel(context.Background())
    s.cancelFuncs[cart_id] = cancel
    s.MonitorLockedItems(ctx, cart_id, 16 * time.Second)


    return nil
}



//func (s *PostgresStore) MonitorLockedItems(cart_id int, timeoutDuration time.Duration) {
func (s *PostgresStore) MonitorLockedItems(ctx context.Context, cart_id int, timeoutDuration time.Duration) {
    doneChan := make(chan bool)
    var isPaid bool
    var err error

    // Use the provided context
    go func() {
        isPaid, err = s.IsPaymentDone(ctx, cart_id)
        doneChan <- true 
    }()

    select {
    case <-doneChan:
        if err != nil {
            fmt.Printf("Error checking payment status for cart %d: %s\n", cart_id, err)
            return
        }
        if !isPaid {
            s.ResetLockedQuantities(cart_id)
        }
    case <-time.After(timeoutDuration):
        fmt.Println("Payment check timeout. Resetting quantities...")
        err := s.ResetLockedQuantities(cart_id)
        if err != nil {
            fmt.Printf("Error resetting locked quantities for cart %d: %s\n", cart_id, err)
        }
    case <-ctx.Done():
        return
    }
}
    


// IsPaymentDone checks if the payment has been done for a cart

func (s *PostgresStore) IsPaymentDone(ctx context.Context, cart_id int) (bool, error) {
    fmt.Println("Started Payment Delay")
    select {
    case <-time.After(14 * time.Second):  // Placeholder time; replace with your actual payment verification duration
        fmt.Println("End Payment Delay")
        return false, nil
    case <-ctx.Done():
        fmt.Println("Payment check was aborted!")
        return false, ctx.Err()
    }
}



// ResetLockedQuantities resets the locked quantities for items in a cart
func (s *PostgresStore) ResetLockedQuantities(cart_id int) error {
    _, err := s.db.Exec(`WITH quantities AS (
        SELECT item_id, quantity 
        FROM cart_item 
        WHERE cart_id = $1
    )
    UPDATE item 
    SET stock_quantity = stock_quantity + quantities.quantity, 
        locked_quantity = locked_quantity - quantities.quantity
    FROM quantities 
    WHERE item.id = quantities.item_id;
    `, cart_id)
    return err
}



