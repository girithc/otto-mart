package store

import "github.com/girithc/pronto-go/types"

func (s *PostgresStore) CreateAddressTable() error {
	// Create the address table without the partial unique constraint
	tableQuery := `
    CREATE TABLE IF NOT EXISTS address (
        id SERIAL PRIMARY KEY,
        customer_id INTEGER REFERENCES customer(id) ON DELETE CASCADE,
        place_id TEXT,
        street_address TEXT NOT NULL,
        line_one_address TEXT NOT NULL,
        line_two_address TEXT NOT NULL,
        city VARCHAR(50),
        state VARCHAR(50),
        zipcode VARCHAR(10),
        is_default BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    `

	_, err := s.db.Exec(tableQuery)
	if err != nil {
		return err
	}

	// Now, add the partial unique index
	indexQuery := `
    CREATE UNIQUE INDEX IF NOT EXISTS idx_one_default_address_per_customer 
    ON address (customer_id) WHERE (is_default IS TRUE)
    `

	_, err = s.db.Exec(indexQuery)
	if err != nil {
		return err
	}

	return nil
}
func (s *PostgresStore) Create_Address(addr *types.Create_Address) (*types.Address, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	defer func() {
		if r := recover(); r != nil { 
			tx.Rollback() // Rollback in case of panic
		}
	}()

	// First, set all other addresses for this customer to is_default=false
	updateQuery := `UPDATE address SET is_default=false WHERE customer_id=$1 AND is_default=true`
	_, err = tx.Exec(updateQuery, addr.Customer_Id)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// Insert the new address and set is_default=true
	query := `INSERT INTO address (customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, is_default) 
		VALUES ($1, $2, $3, $4, $5, $6, $7, true) 
		RETURNING id, customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, created_at`
	row := tx.QueryRow(query, addr.Customer_Id, addr.Street_Address, addr.Line_One_Address, addr.Line_Two_Address, addr.City, addr.State, addr.Zipcode)

	address := &types.Address{}
	err = row.Scan(&address.Id, &address.Customer_Id, &address.Street_Address, &address.Line_One_Address, &address.Line_Two_Address, &address.City, &address.State, &address.Zipcode, &address.Created_At)
	if err != nil {
		tx.Rollback()
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
