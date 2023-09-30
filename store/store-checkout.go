package store

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) Checkout_Items(cart_id int, payment_done bool) error {
	fmt.Println("Entered Checkout_Items")

	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	_, err = tx.Exec(`DECLARE cart_cursor CURSOR FOR SELECT item_id, quantity FROM cart_item WHERE cart_id = $1`, cart_id)
	if err != nil {
		tx.Rollback()
		return err
	}

	for {
		checkout_cart_item := &types.Checkout_Cart_Item{}
		err := tx.QueryRow(`FETCH NEXT FROM cart_cursor`).Scan(&checkout_cart_item.Item_Id, &checkout_cart_item.Quantity)
		if err == sql.ErrNoRows {
			break
		}
		if err != nil {
			tx.Rollback()
			return err
		}

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

		if affectedRows == 0 {
			tx.Rollback()
			return fmt.Errorf("not enough stock for item %d", checkout_cart_item.Item_Id)
		}
	}

	_, err = tx.Exec(`CLOSE cart_cursor`)
	if err != nil {
		tx.Rollback()
		return err
	}

	ctx := context.Background()

	err = s.MonitorLockedItems(ctx, tx, cart_id, 16*time.Second, payment_done)
	if err != nil {
		tx.Rollback()
		return err
	}

	err = tx.Commit()
	if err != nil {
		return err
	}

	return nil
}

// func (s *PostgresStore) MonitorLockedItems(cart_id int, timeoutDuration time.Duration) {
func (s *PostgresStore) MonitorLockedItems(ctx context.Context, tx *sql.Tx, cart_id int, timeoutDuration time.Duration, payment_done bool) error {
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

			_, err = tx.ExecContext(ctx, `UPDATE shopping_cart SET active = false WHERE id = $1`, cart_id)
			if err != nil {
				return fmt.Errorf("error setting cart to inactive for cart %d: %s", cart_id, err)
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

	return nil
}

// IsPaymentDone checks if the payment has been done for a cart

func (s *PostgresStore) IsPaymentDone(ctx context.Context, cart_id int, payment_done bool) (bool, error) {
	fmt.Println("Started Payment Delay")
	select {
	case <-time.After(14 * time.Second): // Placeholder time; replace with your actual payment verification duration
		fmt.Println("End Payment Delay")
		return payment_done, nil
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
