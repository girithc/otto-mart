package store

import (
	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) CreateAddressTable() error {
	query := `create table if not exists address (
		id SERIAL PRIMARY KEY,
		customer_id INTEGER REFERENCES customer(id) ON DELETE CASCADE,
		street_address TEXT NOT NULL,
		line_one_address TEXT NOT NULL,
		line_two_address TEXT NOT NULL,
		city VARCHAR(50),
		state VARCHAR(50),
		zipcode VARCHAR(10),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)
	`

	_, err := s.db.Exec(query)

	return err
}

func (s *PostgresStore) Create_Address(addr *types.Create_Address) (*types.Address, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	defer func() {
		if r := recover(); r != nil { // This catches panics along with Rollback in case of an error.
			tx.Rollback()
		}
	}()

	query := `INSERT INTO address (customer_id, street_address, line_one_address, line_two_address, city, state, zipcode) 
		VALUES ($1, $2, $3, $4, $5, $6, $7) 
		RETURNING id, customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, created_at`
	row := tx.QueryRow(query, addr.Customer_Id, addr.Street_Address, addr.Line_One_Address, addr.Line_Two_Address, addr.City, addr.State, addr.Zipcode)

	address := &types.Address{}
	err = row.Scan(&address.Id, &address.Customer_Id, &address.Street_Address, &address.Line_One_Address, &address.Line_Two_Address, &address.City, &address.State, &address.Zipcode, &address.Created_At)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return address, nil
}

func (s *PostgresStore) Get_Addresses_By_Customer_Id(customer_id int) ([]*types.Address, error) {
	query := `SELECT id, customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, created_at
		FROM address
		WHERE customer_id = $1`

	rows, err := s.db.Query(query, customer_id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var addresses []*types.Address
	for rows.Next() {
		address := &types.Address{}
		err := rows.Scan(&address.Id, &address.Customer_Id, &address.Street_Address, &address.Line_One_Address, &address.Line_Two_Address, &address.City, &address.State, &address.Zipcode, &address.Created_At)
		if err != nil {
			return nil, err
		}
		addresses = append(addresses, address)
	}

	// Check for any error encountered during iteration
	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return addresses, nil
}
