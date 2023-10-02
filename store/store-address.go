package store

func (s *PostgresStore) CreateAddressTable() error {
	query := `create table if not exists address (
		id SERIAL PRIMARY KEY,
		customer_id INTEGER REFERENCES customer(id) ON DELETE CASCADE,
		street_address TEXT NOT NULL,
		city VARCHAR(50) NOT NULL,
		state VARCHAR(50) NOT NULL,
		zipcode VARCHAR(10) NOT NULL,
		country VARCHAR(50) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)
	`

	_, err := s.db.Exec(query)

	return err
}
