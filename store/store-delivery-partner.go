package store

import (
	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateDeliveryPartnerTable() error {
	//fmt.Println("Entered CreateItemTable")

	query := `create table if not exists delivery_partner(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		phone VARCHAR(10) NOT NULL, 
		address TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateItemTable")

	return err
}