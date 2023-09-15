package store

import (
	"database/sql"
	"pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCartItemTable() error {
	//fmt.Println("Entered CreateCartItemTable")

	query := `create table if not exists cart_item (
		id SERIAL PRIMARY KEY,
		cart_id INT REFERENCES Shopping_Cart(id) ON DELETE CASCADE,
		item_id INT REFERENCES Item(id) ON DELETE CASCADE,
		quantity INT NOT NULL 
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateCartItemTable")

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
    
    var quantity int
    err := s.db.QueryRow(query, cart_id, item_id).Scan(&quantity)
    if err != nil {
        if err == sql.ErrNoRows {
            // No matching record found, the item is not in the cart
            return false, nil
        }
        // Handle other database errors
        return false, err
    }
    
    // Check if the quantity is less than the stock_quantity parameter
    return ((quantity + item_quantity) <= stock_quantity) , nil
}

func (s *PostgresStore) Update_Cart_Item_Quantity(cart_id int, item_id int, quantity int)(*types.Cart_Item, error) {
	query := `
    UPDATE cart_item
    SET quantity = quantity + $1
    WHERE cart_id = $2 AND item_id = $3
	RETURNING id, cart_id, item_id, quantity
	`

	rows, err := s.db.Query(query, quantity,  cart_id, item_id)
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

func (s *PostgresStore) Add_Cart_Item(cart_id int, item_id int, quantity int)(*types.Cart_Item, error) {
	query := `insert into cart_item
	(cart_id, item_id, quantity) 
	values ($1, $2, $3) returning id, cart_id, item_id, quantity
	`
	rows, err := s.db.Query(
		query,
		cart_id,
		item_id, 
		quantity)
	
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

	return cart_items[0], nil
}

func (s *PostgresStore) Get_All_Cart_Items(cart_id int)([]*types.Cart_Item, error) {
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

func scan_Into_Cart_Item_Quantity(rows *sql.Rows) (*types.Cart_Item_Quantity, error) {
	cart_item_quantity := new(types.Cart_Item_Quantity)
	err := rows.Scan(
		&cart_item_quantity.Quantity,
	)

	return cart_item_quantity, err
}