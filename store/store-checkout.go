package store

import (
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

func (s *PostgresStore) cartLockStock(cartId int, tx *sql.Tx) (string, error) {
	// Insert a record into the cart_lock table
	lockType := "lock-stock"
	expiresAt := time.Now().Add(1 * time.Minute) // 1 minute from now
	var sign string
	err := tx.QueryRow(`INSERT INTO cart_lock (cart_id, lock_type, lock_timeout) VALUES ($1, $2, $3) RETURNING sign`, cartId, lockType, expiresAt).Scan(&sign)
	if err != nil {
		tx.Rollback()
		return "", fmt.Errorf("error inserting lock record for cart %d: %v", cartId, err)
	}

	return sign, nil
}

func (s *PostgresStore) cartLockUpdate(tx *sql.Tx, cartId int, cash bool) (string, error) {
	// Update the cart_lock record
	updateCartLockQuery := `
        UPDATE cart_lock 
        SET completed = 'success', last_updated = CURRENT_TIMESTAMP 
        WHERE cart_id = $1 AND completed = 'started'`
	_, err := tx.Exec(updateCartLockQuery, cartId)
	if err != nil {
		return "", fmt.Errorf("failed to update cart_lock for cart %d: %s", cartId, err)
	}

	var insertCartLockQuery string
	if !cash {
		// Calculate the expiration timestamp
		expiresAt := time.Now().Add((1 * time.Minute) + (10 * time.Second))

		// Insert a new cart_lock record
		insertCartLockQuery = `INSERT INTO cart_lock (cart_id, lock_type, completed, lock_timeout) VALUES ($1, 'pay-verify', 'started', $2) RETURNING sign`
		row := tx.QueryRow(insertCartLockQuery, cartId, expiresAt)

		// Retrieve and return the sign value
		var sign string
		if err := row.Scan(&sign); err != nil {
			return "", fmt.Errorf("error retrieving sign value for cart %d: %s", cartId, err)
		}

		return sign, nil
	} else {
		// Insert a new cart_lock record
		insertCartLockQuery = `INSERT INTO cart_lock (cart_id, lock_type, completed) VALUES ($1, 'paid', 'success') RETURNING sign`
		row := tx.QueryRow(insertCartLockQuery, cartId)

		// Retrieve and return the sign value
		var sign string
		if err := row.Scan(&sign); err != nil {
			return "", fmt.Errorf("error retrieving sign value for cart %d: %s", cartId, err)
		}

		return sign, nil
	}
}

func (s *PostgresStore) CreateOrder(tx *sql.Tx, cart_id int, paymentType string) (bool, error) {
	var storeID sql.NullInt64

	// get cart items
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

	err = tx.Commit()
	if err != nil {
		return true, err
	}

	return true, nil
}

// /helper functions end

type IsLockStock struct {
	Lock bool   `json:"lock"`
	Sign string `json:"sign"`
}

func (s *PostgresStore) LockStock(cart_id int) (IsLockStock, error) {
	var resp IsLockStock
	cartItems, err := s.getCartItems(cart_id)
	if err != nil {
		resp.Lock = false
		resp.Sign = ""
		return resp, err
	}

	// Transaction starts
	tx, err := s.db.Begin()
	if err != nil {
		resp.Lock = false
		resp.Sign = ""
		return resp, err
	}

	// Deferred rollback in case of any error during the transaction
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	areItemsLocked, err := s.lockItems(cartItems, tx)
	if err != nil {
		resp.Lock = areItemsLocked
		resp.Sign = ""
		return resp, err
	}

	sign, err := s.cartLockStock(cart_id, tx)
	if err != nil {
		resp.Lock = false
		resp.Sign = ""
		return resp, err
	}

	err = s.CreateTransaction(tx, cart_id)
	if err != nil {
		fmt.Print("Error in Creating Transaction: ", err)
		resp.Lock = false
		resp.Sign = ""
		return resp, err
	}

	_ = s.CreateCloudTask(cart_id, "lock-stock", sign)

	err = tx.Commit()
	if err != nil {
		resp.Lock = false
		resp.Sign = ""
		return resp, fmt.Errorf("error in committing transaction: %v", err)
	}

	resp.Lock = true
	resp.Sign = sign
	return resp, nil
}

func (s *PostgresStore) PayStock(cart_id int) (bool, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return false, fmt.Errorf("failed to start transaction: %s", err)
	}

	_, err = s.cartLockUpdate(tx, cart_id, false)
	if err != nil {
		return false, err
	}

	err = tx.Commit()
	if err != nil {
		return false, fmt.Errorf("error committing transaction: %s", err)
	}

	return true, nil
}

func (s *PostgresStore) PayStockCash(cart_id int) (bool, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return false, fmt.Errorf("failed to start transaction: %s", err)
	}

	_, err = s.cartLockUpdate(tx, cart_id, true)
	if err != nil {
		return false, err
	}

	// Start a transaction
	success, err := s.CreateOrder(tx, cart_id, "cash")
	if err != nil {
		return success, err
	}

	err = tx.Commit()
	if err != nil {
		return false, fmt.Errorf("error committing transaction: %s", err)
	}

	return success, nil
	// If all operations are successful, commit the transaction
}

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
