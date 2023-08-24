package store

import (
	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable() error {
	//fmt.Println("Entered CreateShoppingCartTable")

	query := `create table if not exists shopping_cart (
		id SERIAL PRIMARY KEY,
    	customer_id INT REFERENCES Customer(id) ON DELETE CASCADE
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateShoppingCartTable")

	return err
}