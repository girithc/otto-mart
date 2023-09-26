package store

import (
	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateOrderTable() error {
	//fmt.Println("Entered CreateItemTable")

	query := `create table if not exists order(
		id SERIAL PRIMARY KEY,
		number VARCHAR(10) NOT NULL,
		delivery_partner_id INT REFERENCES Delivery_Partner(id) ON DELETE CASCADE NOT NULL,
		cart_id INT REFERENCES Shopping_Cart(id) ON DELETE CASCADE NOT NULL,
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
		delivery_address TEXT NOT NULL,
		order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateItemTable")

	return err
}