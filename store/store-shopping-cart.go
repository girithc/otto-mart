package store

import (
	"database/sql"
	"pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable() error {
	query := `create table if not exists shopping_cart (
		id SERIAL PRIMARY KEY,
    	customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
		order_id INT, 
		store_id INT REFERENCES Store(id) ON DELETE CASCADE,
		active BOOLEAN NOT NULL DEFAULT true,
		address TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    	CONSTRAINT unique_active_cart_per_user UNIQUE (customer_id, active)
	)`
	_, err := s.db.Exec(query)
	return err
}


func (s *PostgresStore) Create_Shopping_Cart(cart *types.Create_Shopping_Cart) (*types.Shopping_Cart, error) {
	query := `insert into shopping_cart
	(customer_id, active) 
	values ($1, $2) returning id, customer_id, active, created_at
	`
	rows, err := s.db.Query(
		query,
		cart.Customer_Id,
		true)

	if err != nil {
		return nil, err
	}


	shopping_carts := []*types.Shopping_Cart{}
	
	for rows.Next() {
		shopping_cart, err := scan_Into_Shopping_Cart(rows)
		if err != nil {
			return nil, err
		}
		shopping_carts = append(shopping_carts, shopping_cart)
	}


	return shopping_carts[0], nil
}

func (s *PostgresStore) Get_All_Active_Shopping_Carts() ([]*types.Shopping_Cart, error) {
	rows, err := s.db.Query("select * from shopping_cart where active = $1", true)
	
	if err != nil {
		return nil, err
	}


	shopping_carts := []*types.Shopping_Cart{}
	
	for rows.Next() {
		shopping_cart, err := scan_Into_Shopping_Cart(rows)
		if err != nil {
			return nil, err
		}
		shopping_carts = append(shopping_carts, shopping_cart)
	}


	return shopping_carts, nil
}

func (s *PostgresStore) Get_Shopping_Cart_By_Customer_Id(customer_id int, active bool) (*types.Shopping_Cart, error) {
	rows, err := s.db.Query("select * from shopping_cart where active = $1 and customer_id = $2", active, customer_id)
	
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		return scan_Into_Shopping_Cart(rows)
	}

	return nil, nil
}

func (s *PostgresStore) DoesCartExist(cartID int) (bool, error) {
    var count int
    err := s.db.QueryRow("SELECT COUNT(*) FROM shopping_cart WHERE id = $1 AND active = true", cartID).Scan(&count)
    if err != nil {
        return false, err
    }

    return count > 0, nil
}


func scan_Into_Shopping_Cart(rows *sql.Rows) (*types.Shopping_Cart, error) {
	cart := new(types.Shopping_Cart)

	// Use sql.NullInt64 for order_id and store_id to handle NULL values
	var orderID sql.NullInt64
	var storeID sql.NullInt64
	// Use sql.NullString for address to handle NULL values
	var address sql.NullString
	
	err := rows.Scan(
		&cart.ID,
		&cart.Customer_Id,
		&orderID,
		&storeID,
		&cart.Active,
		&address, // Scan into sql.NullString variable
		&cart.Created_At,
	)

	// If orderID has a valid value (i.e., it's not NULL), set it to cart.Order_Id
	if orderID.Valid {
		cart.Order_Id = int(orderID.Int64)
	}
	if storeID.Valid {
		cart.Store_Id = int(storeID.Int64)
	}
	// If address has a valid value (i.e., it's not NULL), set it to cart.Address
	if address.Valid {
		cart.Address = address.String
	}

	return cart, err
}

