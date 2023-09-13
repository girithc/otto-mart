package store

import (
	"database/sql"
	"pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable() error {
	//fmt.Println("Entered CreateShoppingCartTable")

	query := `create table if not exists shopping_cart (
		id SERIAL PRIMARY KEY,
    	customer_id INT REFERENCES Customer(id) ON DELETE CASCADE,
		active BOOLEAN NOT NULL DEFAULT true,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    	CONSTRAINT unique_active_cart_per_user UNIQUE (customer_id, active)
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateShoppingCartTable")

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

func scan_Into_Shopping_Cart(rows *sql.Rows) (*types.Shopping_Cart, error) {
	cart := new(types.Shopping_Cart)
	err := rows.Scan(
		&cart.ID,
		&cart.Customer_Id,
		&cart.Active,
		&cart.Created_At,
	)

	return cart, err
}