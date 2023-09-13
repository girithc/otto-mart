package store

import (
	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable() error {
	//fmt.Println("Entered CreateShoppingCartTable")

	query := `create table if not exists shopping_cart (
		id SERIAL PRIMARY KEY,
    	customer_id INT REFERENCES Customer(id) ON DELETE CASCADE,
		active BOOLEAN NOT NULL DEFAULT true,
    	CONSTRAINT unique_active_cart_per_user UNIQUE (customer_id, active)
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateShoppingCartTable")

	return err
}