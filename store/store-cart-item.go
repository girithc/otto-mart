package store

import (
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