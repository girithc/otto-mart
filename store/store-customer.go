package store

import (
	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCustomerTable() error {
	//fmt.Println("Entered CreateCustomerTable")

	query := `create table if not exists customer (
		id SERIAL PRIMARY KEY,
		customer_name VARCHAR(100) NOT NULL,
		email VARCHAR(100),
		phone_number VARCHAR(10) NOT NULL, 
		address VARCHAR(200)
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateCustomerTable")

	return err
}