package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCartItemTable() error {
	// fmt.Println("Entered CreateCartItemTable")

	query := `create table if not exists cart_item (
		id SERIAL PRIMARY KEY,
		cart_id INT,
		item_id INT REFERENCES item_store(id) ON DELETE CASCADE,
		quantity INT NOT NULL 
	)`

	_, err := s.db.Exec(query)

	// fmt.Println("Exiting CreateCartItemTable")

	return err
}

func (s *PostgresStore) SetCartItemForeignKeys() error {
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

	_, err := s.db.Exec(query)
	return err
}

func (s *PostgresStore) DoesItemExist(cart_id int, item_id int) (bool, error) {
	var count int
	err := s.db.QueryRow("SELECT COUNT(*) FROM cart_item WHERE cart_id = $1 AND item_id = $2", cart_id, item_id).Scan(&count)
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

func (s *PostgresStore) Add_Cart_Item(cart_id int, item_id int, quantity int) (*types.Cart_Item, error) {
	// Begin a new transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	// Check if shopping_cart exists
	var cartExists bool
	if err := tx.QueryRow("SELECT EXISTS(SELECT 1 FROM shopping_cart WHERE id=$1)", cart_id).Scan(&cartExists); err != nil {
		tx.Rollback()
		return nil, err
	}
	if !cartExists {
		tx.Rollback()
		return nil, fmt.Errorf("shopping cart with id %d does not exist", cart_id)
	}

	// Check if item exists and is in stock
	var stockQuantity int
	if err := tx.QueryRow("SELECT stock_quantity FROM item_store WHERE item_id=$1", item_id).Scan(&stockQuantity); err != nil {
		tx.Rollback()
		return nil, err
	}
	if stockQuantity < quantity {
		tx.Rollback()
		return nil, fmt.Errorf("not enough stock for item id %d", item_id)
	}

	// Check if item is already in the cart
	var currentQuantity int
	err = tx.QueryRow("SELECT quantity FROM cart_item WHERE cart_id=$1 AND item_id=$2", cart_id, item_id).Scan(&currentQuantity)

	cartItem := &types.Cart_Item{}
	if err == sql.ErrNoRows {
		err = tx.QueryRow("INSERT INTO cart_item (cart_id, item_id, quantity) VALUES ($1, $2, $3) RETURNING id, cart_id, item_id, quantity", cart_id, item_id, quantity).Scan(&cartItem.ID, &cartItem.CartId, &cartItem.ItemId, &cartItem.Quantity)
	} else if err == nil {
		newTotalQuantity := currentQuantity + quantity
		if newTotalQuantity > stockQuantity {
			tx.Rollback()
			// nil, fmt.Errorf("not enough stock for item id %d. current item quantity {%d} in cart and the new addition exceeds available stock {%d}.", item_id, newTotalQuantity, )
			return nil, fmt.Errorf("not enough stock for item id %d. need total quantity %d. item stock quantity %d. requested quantity %d", item_id, newTotalQuantity, currentQuantity, quantity)
		}
		err = tx.QueryRow("UPDATE cart_item SET quantity=quantity+$1 WHERE cart_id=$2 AND item_id=$3 RETURNING id, cart_id, item_id, quantity", quantity, cart_id, item_id).Scan(&cartItem.ID, &cartItem.CartId, &cartItem.ItemId, &cartItem.Quantity)
	} else {
		tx.Rollback()
		return nil, err
	}

	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

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
            i.id, 
            i.name, 
            istore.price::numeric::float8, 
            ii.image_url,  -- Assumes that we are getting image from item_image table
            istore.stock_quantity, 
            ci.quantity
        FROM cart_item ci
        JOIN item i ON ci.item_id = i.id
        JOIN item_store istore ON i.id = istore.item_id
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
		if err := rows.Scan(&cart_item.Id, &cart_item.Name, &cart_item.Price, &cart_item.Image, &cart_item.Stock_Quantity, &cart_item.Quantity); err != nil {
			return nil, err
		}
		cart_items = append(cart_items, cart_item)
	}

	return cart_items, nil
}

func (s *PostgresStore) Get_Items_List_From_Active_Cart_By_Customer_Id(customer_id int) ([]*types.Cart_Item_Item_List, error) {
	rows, err := s.db.Query(`
        SELECT i.id, i.name, i.price::numeric::float8, i.image, i.stock_quantity, ci.quantity
        FROM shopping_cart sc
        JOIN cart_item ci ON ci.cart_id = sc.id
        JOIN item i ON ci.item_id = i.id
        WHERE sc.active = $1 AND sc.customer_id = $2;
    `, true, customer_id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	cart_items := []*types.Cart_Item_Item_List{}
	for rows.Next() {
		cart_item, err := scan_Into_Cart_Item_Item_List(rows)
		if err != nil {
			return nil, err
		}
		cart_items = append(cart_items, cart_item)
	}

	// Check for errors after iterating through rows
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return cart_items, nil
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

func scan_Into_Cart_Item_Item_List(rows *sql.Rows) (*types.Cart_Item_Item_List, error) {
	cart_item_item_list := new(types.Cart_Item_Item_List)
	err := rows.Scan(
		&cart_item_item_list.Id,
		&cart_item_item_list.Name,
		&cart_item_item_list.Price,
		&cart_item_item_list.Image,
		&cart_item_item_list.Stock_Quantity,
		&cart_item_item_list.Quantity,
	)

	return cart_item_item_list, err
}
