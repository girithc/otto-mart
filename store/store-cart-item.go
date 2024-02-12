package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCartItemTable(tx *sql.Tx) error {
	fmt.Println("Entered CreateCartItemTable")

	query := `
    CREATE TABLE IF NOT EXISTS cart_item (
        id SERIAL PRIMARY KEY,
        cart_id INT,
        item_id INT REFERENCES item_store(id) ON DELETE CASCADE,
        quantity INT NOT NULL CHECK (quantity >= 0),
        sold_price INT NOT NULL CHECK (sold_price >= 0),
        discount_applied INT NOT NULL DEFAULT 0 CHECK (discount_applied >= 0)
    )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating cart_item table: %w", err)
	}

	fmt.Println("Exiting CreateCartItemTable")
	return nil
}

func (s *PostgresStore) SetCartItemForeignKey(tx *sql.Tx) error {
	// Add foreign key constraint to the already created table
	query := `
	DO $$
	BEGIN
		IF NOT EXISTS (
			SELECT constraint_name 
			FROM information_schema.table_constraints 
			WHERE table_name = 'cart_item' AND constraint_name = 'cart_item_cart_id_fkey'
		) THEN
			ALTER TABLE cart_item 
			ADD CONSTRAINT cart_item_cart_id_fkey 
			FOREIGN KEY (cart_id) REFERENCES Shopping_Cart(id) ON DELETE CASCADE;
		END IF;
	END
	$$;
	`

	_, err := tx.Exec(query)
	return err
}

func (s *PostgresStore) DoesItemExist(cart_id int, item_id int) (bool, error) {
	var itemStoreId int

	err := s.db.QueryRow("SELECT id FROM item_store WHERE item_id=$1 AND store_id=1", item_id).Scan(&itemStoreId)
	if err != nil {
		return false, err
	}

	var count int
	err = s.db.QueryRow("SELECT COUNT(*) FROM cart_item WHERE cart_id = $1 AND item_id = $2", cart_id, itemStoreId).Scan(&count)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

func (s *PostgresStore) IsItemInStock(stock_quantity int, item_id int, cart_id int, item_quantity int) (bool, error) {
	// Query to retrieve the quantity from cart_item table
	query := `
        SELECT quantity FROM cart_item
        WHERE cart_id = $1 AND item_id = $2
    `

	var quantity int = 0
	err := s.db.QueryRow(query, cart_id, item_id).Scan(&quantity)
	if err != nil {
		if err != sql.ErrNoRows {
			// Handle other database errors
			fmt.Println("Database Error")
			return false, err
		}
		// no rows returned - its fine
	}

	fmt.Println("Quantity: ", quantity)
	fmt.Println("Item Quantity: ", item_quantity)
	fmt.Println("Stock Quantity: ", stock_quantity)

	// Check if the quantity is less than the stock_quantity parameter
	return ((quantity + item_quantity) <= stock_quantity), nil
}

func (s *PostgresStore) Update_Cart_Item_Quantity(cart_id int, item_id int, quantity int) (*types.Cart_Item, error) {
	query := `
    UPDATE cart_item
    SET quantity = quantity + $1
    WHERE cart_id = $2 AND item_id = $3
	RETURNING id, cart_id, item_id, quantity
	`

	rows, err := s.db.Query(query, quantity, cart_id, item_id)
	if err != nil {
		return nil, err
	}

	cart_items := []*types.Cart_Item{}

	for rows.Next() {
		cart_item, err := scan_Into_Cart_Item(rows)
		if err != nil {
			return nil, err
		}
		cart_items = append(cart_items, cart_item)
	}

	if len(cart_items) == 0 {
		// No records were updated
		return nil, nil
	}

	updatedQuantity := cart_items[0].Quantity

	if updatedQuantity == 0 {
		// Quantity is zero, you deleted a record
		// You can retrieve the remaining records for the same cart_id
		deleteQuery := `
            DELETE FROM cart_item
            WHERE cart_id = $1 AND item_id = $2
        `

		_, err := s.db.Exec(deleteQuery, cart_id, item_id)
		if err != nil {
			return nil, err
		}

		return nil, nil
	}

	return cart_items[0], nil
}

func (s *PostgresStore) Add_Cart_Item(cartId int, itemId int, quantity int) (*types.CartDetails, error) {
	// Begin a new transaction

	var outOfStock bool = false
	var finalQuantity int = 0
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	// Check if item exists in the item_store
	var stockQuantity int
	if err := tx.QueryRow("SELECT stock_quantity FROM item_store WHERE item_id=$1", itemId).Scan(&stockQuantity); err != nil {
		tx.Rollback()
		return nil, err
	}

	// Add Items
	if quantity > 0 {
		if stockQuantity < quantity {
			tx.Rollback()
			return nil, fmt.Errorf("not enough stock for item id %d", itemId)
		}
	}

	var cartItemQuantity int
	cartItem := &types.CartDetails{}

	err = tx.QueryRow("SELECT quantity FROM cart_item WHERE cart_id=$1 AND item_id=$2", cartId, itemId).Scan(&cartItemQuantity)

	// item not in cart and trying to reduce quantity
	if err == sql.ErrNoRows {
		if quantity < 0 {
			tx.Rollback()
			return nil, fmt.Errorf("item not in cart")
		} else if quantity > 0 {
			_, err = tx.Exec("INSERT INTO cart_item (cart_id, item_id, quantity, sold_price) VALUES ($1, $2, $3, (SELECT store_price FROM item_store WHERE item_id=$2 AND store_id=1))", cartId, itemId, quantity)
			if err != nil {
				tx.Rollback()
				return nil, err
			}
			finalQuantity = quantity
		}
	} else if err == nil {

		newTotalQuantity := cartItemQuantity + quantity
		if newTotalQuantity < 0 {
			tx.Rollback()
			return nil, fmt.Errorf("resulting quantity cannot be negative")
		} else if newTotalQuantity == 0 {
			_, err = tx.Exec("DELETE FROM cart_item WHERE cart_id=$1 AND item_id=$2", cartId, itemId)
		} else if newTotalQuantity > stockQuantity {
			outOfStock = true
			if stockQuantity <= 0 {
				_, err = tx.Exec("DELETE FROM cart_item WHERE cart_id=$1 AND item_id=$2", cartId, itemId)
			} else {
				_, err = tx.Exec("UPDATE cart_item SET quantity=$1 WHERE cart_id=$2 AND item_id=$3", stockQuantity, cartId, itemId)
				finalQuantity = stockQuantity
			}
		} else {
			_, err = tx.Exec("UPDATE cart_item SET quantity=$1 WHERE cart_id=$2 AND item_id=$3", newTotalQuantity, cartId, itemId)
			finalQuantity = newTotalQuantity
		}
		if err != nil {
			tx.Rollback()
			return nil, err
		}
	} else {
		tx.Rollback()
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	// Recalculate cart totals after adding/removing item
	err = s.CalculateCartTotal(cartId)
	if err != nil {
		fmt.Print("Error in CalculateCartTotal() inside Add_Cart_Item()", err)
	}

	// Query the updated shopping cart
	cartQuery := `
		SELECT item_cost, delivery_fee, platform_fee, small_order_fee, rain_fee, 
			high_traffic_surcharge, packaging_fee, peak_time_surcharge, subtotal, 
			discounts, number_of_items
		FROM shopping_cart
		WHERE id = $1`

	err = s.db.QueryRow(cartQuery, cartId).Scan(&cartItem.ItemCost, &cartItem.DeliveryFee, &cartItem.PlatformFee,
		&cartItem.SmallOrderFee, &cartItem.RainFee, &cartItem.HighTrafficSurcharge,
		&cartItem.PackagingFee, &cartItem.PeakTimeSurcharge, &cartItem.Subtotal,
		&cartItem.Discounts, &cartItem.Quantity)
	if err != nil {
		return nil, err
	}

	cartItem.CartId = cartId
	cartItem.ItemId = itemId
	cartItem.Quantity = finalQuantity
	cartItem.OutOfStock = outOfStock

	// Return the cart item details
	return cartItem, nil
}

func (s *PostgresStore) Get_Cart_Items_By_Cart_Id(cart_id int) ([]*types.Cart_Item, error) {
	rows, err := s.db.Query("select * from cart_item where cart_id = $1", cart_id)
	if err != nil {
		return nil, err
	}

	cart_items := []*types.Cart_Item{}

	for rows.Next() {
		cart_item, err := scan_Into_Cart_Item(rows)
		if err != nil {
			return nil, err
		}
		cart_items = append(cart_items, cart_item)
	}

	return cart_items, nil
}

func (s *PostgresStore) Get_Items_List_From_Cart_Items_By_Cart_Id(cart_id int) ([]*types.Cart_Item_Item_List, error) {
	rows, err := s.db.Query(`
        SELECT 
            ci.item_id,  -- Changed from i.id to ci.item_id for clarity
            i.name, 
            istore.mrp_price::numeric::float8, 
            ii.image_url, 
            istore.stock_quantity, 
            ci.quantity, 
            ci.sold_price,
            (istore.stock_quantity >= ci.quantity) AS in_stock 
        FROM cart_item ci
        JOIN item_store istore ON ci.item_id = istore.item_id
        JOIN item i ON istore.item_id = i.id
        LEFT JOIN item_image ii ON i.id = ii.item_id
        WHERE ci.cart_id = $1;
    `, cart_id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	cart_items := []*types.Cart_Item_Item_List{}
	for rows.Next() {
		cart_item := &types.Cart_Item_Item_List{}
		if err := rows.Scan(&cart_item.Id, &cart_item.Name, &cart_item.Price, &cart_item.Image, &cart_item.Stock_Quantity, &cart_item.Quantity, &cart_item.SoldPrice, &cart_item.InStock); err != nil {
			return nil, err
		}

		// Process each cart item based on its stock status
		if !cart_item.InStock {
			if cart_item.Stock_Quantity > 0 {
				// Update cart_item quantity to stock_quantity
				_, err := s.db.Exec(`UPDATE cart_item SET quantity = $1 WHERE item_id = $2 AND cart_id = $3`, cart_item.Stock_Quantity, cart_item.Id, cart_id)
				if err != nil {
					return nil, err // Consider handling this more gracefully in a real application
				}
				cart_item.Quantity = cart_item.Stock_Quantity
			} else {
				// Delete cart_item record if stock_quantity is 0
				_, err := s.db.Exec(`DELETE FROM cart_item WHERE item_id = $1 AND cart_id = $2`, cart_item.Id, cart_id)
				if err != nil {
					return nil, err // Consider handling this more gracefully in a real application
				}
				cart_item.Quantity = 0
			}
		}

		cart_items = append(cart_items, cart_item)
	}

	return cart_items, nil
}

func (s *PostgresStore) GetItemsListFromCartByCustomerId(customerId int, cartId int) (*types.CartItemResponse, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback() // Ensure rollback in case of error

	// Fetch cart items
	cartItems, err := s.fetchCartItems(tx, cartId)
	if err != nil {
		return nil, err // Error is already formatted
	}

	fmt.Println("Cart ID: ", cartId)
	println("Cart Items: ", cartItems)

	// Fetch cart details
	cartDetails, err := s.fetchCartDetails(tx, cartId)
	if err != nil {
		return nil, err // Error is already formatted
	}
	fmt.Println("Cart Details: ", cartDetails)

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	// Prepare the response
	cartResponse := &types.CartItemResponse{
		CartDetails:   cartDetails,
		CartItemsList: cartItems,
	}

	// Calculate total quantity
	var totalQuantity int
	for _, item := range cartItems {
		totalQuantity += item.Quantity
	}
	cartResponse.CartDetails.Quantity = totalQuantity

	return cartResponse, nil
}

// fetchCartItems retrieves the list of items in the cart
func (s *PostgresStore) fetchCartItems(tx *sql.Tx, cartId int) ([]*types.Cart_Item_Item_List, error) {
	query := `
        SELECT 
            i.id, 
            i.name, 
            istore.mrp_price::numeric::float8 AS price, 
            MIN(ii.image_url) AS main_image, 
            istore.stock_quantity, 
            ci.quantity, 
            ci.sold_price
        FROM 
            cart_item ci
            JOIN item_store istore ON ci.item_id = istore.item_id
            JOIN item i ON istore.item_id = i.id
            LEFT JOIN item_image ii ON i.id = ii.item_id
        WHERE 
            ci.cart_id = $1
        GROUP BY 
            i.id, i.name, istore.mrp_price, istore.stock_quantity, ci.quantity, ci.sold_price
    `

	rows, err := tx.Query(query, cartId)
	if err != nil {
		return nil, fmt.Errorf("error querying cart items: %w", err)
	}
	defer rows.Close()

	var cartItems []*types.Cart_Item_Item_List
	for rows.Next() {
		cartItem, err := scanIntoCartItemItemList(rows)
		if err != nil {
			return nil, fmt.Errorf("error scanning cart item: %w", err)
		}
		cartItems = append(cartItems, cartItem)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating cart items: %w", err)
	}

	return cartItems, nil
}

// fetchCartDetails retrieves the details of the cart
func (s *PostgresStore) fetchCartDetails(tx *sql.Tx, cartId int) (*types.CartDetails, error) {
	cartItem := &types.CartDetails{}
	cartQuery := `
        SELECT 
            item_cost, delivery_fee, platform_fee, small_order_fee, rain_fee, 
            high_traffic_surcharge, packaging_fee, peak_time_surcharge, subtotal, 
            discounts
        FROM 
            shopping_cart
        WHERE 
            id = $1
    `

	err := tx.QueryRow(cartQuery, cartId).Scan(
		&cartItem.ItemCost, &cartItem.DeliveryFee, &cartItem.PlatformFee,
		&cartItem.SmallOrderFee, &cartItem.RainFee, &cartItem.HighTrafficSurcharge,
		&cartItem.PackagingFee, &cartItem.PeakTimeSurcharge, &cartItem.Subtotal,
		&cartItem.Discounts,
	)
	if err != nil {
		return nil, fmt.Errorf("error querying cart details: %w", err)
	}

	cartItem.OutOfStock = false

	return cartItem, nil
}

// scanIntoCartItemItemList scans a row into a Cart_Item_Item_List struct
func scanIntoCartItemItemList(row *sql.Rows) (*types.Cart_Item_Item_List, error) {
	cartItem := new(types.Cart_Item_Item_List)
	err := row.Scan(
		&cartItem.Id,
		&cartItem.Name,
		&cartItem.Price,
		&cartItem.Image,
		&cartItem.Stock_Quantity,
		&cartItem.Quantity,
		&cartItem.SoldPrice,
	)
	return cartItem, err
}

func scan_Into_Cart_Item(rows *sql.Rows) (*types.Cart_Item, error) {
	cart_item := new(types.Cart_Item)
	err := rows.Scan(
		&cart_item.ID,
		&cart_item.CartId,
		&cart_item.ItemId,
		&cart_item.Quantity,
	)

	return cart_item, err
}
