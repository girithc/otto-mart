package store

import (
	"database/sql"
	"math"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) CreateAddressTable(tx *sql.Tx) error {
	// Create the address table without the partial unique constraint
	tableQuery := `
    CREATE TABLE IF NOT EXISTS address (
		id SERIAL PRIMARY KEY,
		customer_id INTEGER REFERENCES customer(id) ON DELETE CASCADE,
		latitude DECIMAL(10, 8),
		longitude DECIMAL(11, 8),
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

	_, err := tx.Exec(tableQuery)
	if err != nil {
		return err
	}

	return nil
}

func (s *PostgresStore) Create_Address(addr *types.Create_Address) (*types.Address, error) {
	// Retrieve customer_id using the provided phone number
	var customerID int

	println("CustomerID: ", addr.Customer_Id)
	err := s.db.QueryRow(`SELECT id FROM customer WHERE phone = $1`, addr.Customer_Id).Scan(&customerID)
	if err != nil {
		return nil, err
	}

	// First, set all other addresses for this customer to is_default=false
	updateQuery := `UPDATE address SET is_default=false WHERE customer_id=$1 AND is_default=true`
	_, err = s.db.Exec(updateQuery, customerID)
	if err != nil {
		return nil, err
	}

	println("Set address to false")

	// Insert the new address and set is_default=true
	query := `INSERT INTO address (customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, latitude, longitude, is_default) 
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true) 
              RETURNING id,  street_address, line_one_address, line_two_address, city, state, zipcode, is_default, latitude, longitude, created_at`
	row := s.db.QueryRow(query, customerID, addr.Street_Address, addr.Line_One_Address, addr.Line_Two_Address, addr.City, addr.State, addr.Zipcode, addr.Latitude, addr.Longitude)

	println("insert new address")

	address := &types.Address{}
	err = row.Scan(&address.Id, &address.Street_Address, &address.Line_One_Address, &address.Line_Two_Address, &address.City, &address.State, &address.Zipcode, &address.Is_Default, &address.Latitude, &address.Longitude, &address.Created_At)
	if err != nil {
		return nil, err
	}

	address.Customer_Id = customerID
	println("done executing")
	return address, nil
}

func (s *PostgresStore) Get_Addresses_By_Customer_Id(customer_id int, is_default bool) ([]*types.Address, error) {
	// Include place_id, latitude, and longitude in the SELECT statement
	query := `SELECT id, customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, is_default, latitude, longitude, created_at
		FROM address
		WHERE customer_id = $1 AND is_default = $2`

	rows, err := s.db.Query(query, customer_id, is_default)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var addresses []*types.Address
	for rows.Next() {
		address := &types.Address{}
		// Include place_id, latitude, and longitude in the Scan method call
		err := rows.Scan(&address.Id, &address.Customer_Id, &address.Street_Address, &address.Line_One_Address, &address.Line_Two_Address, &address.City, &address.State, &address.Zipcode, &address.Is_Default, &address.Latitude, &address.Longitude, &address.Created_At)
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

	if len(addresses) == 0 {
		// No results found, return an empty slice
		return []*types.Address{}, nil
	}

	return addresses, nil
}

func (s *PostgresStore) MakeDefaultAddress(customer_id int, address_id int, is_default bool) (*types.Default_Address, error) {
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // Rollback the transaction if anything goes wrong

	// Set the current default address for the customer to false
	_, err = tx.Exec(`UPDATE address SET is_default = false WHERE customer_id = $1 AND is_default = true`, customer_id)
	if err != nil {
		return nil, err
	}

	// Set the provided address_id for the customer to true
	_, err = tx.Exec(`UPDATE address SET is_default = true WHERE customer_id = $1 AND id = $2`, customer_id, address_id)
	if err != nil {
		return nil, err
	}

	// Query the updated default address for the customer
	var addr types.Default_Address
	err = tx.QueryRow(`SELECT * FROM address WHERE customer_id = $1 AND is_default = true`, customer_id).Scan(
		&addr.Id, &addr.Customer_Id, &addr.Latitude, &addr.Longitude, &addr.Street_Address,
		&addr.Line_One_Address, &addr.Line_Two_Address, &addr.City, &addr.State, &addr.Zipcode, &addr.Is_Default, &addr.Created_At,
	)
	if err != nil {
		return nil, err
	}

	// Find a store with the same latitude and longitude
	err = tx.QueryRow(`SELECT id FROM store WHERE latitude = $1 AND longitude = $2 LIMIT 1`, addr.Latitude, addr.Longitude).Scan(&addr.StoreId)
	if err != nil {
		addr.Deliverable = false
	} else {
		addr.Deliverable = true
	}

	// If everything has proceeded without errors, commit the transaction
	err = tx.Commit()
	if err != nil {
		return nil, err
	}

	return &addr, nil
}

// Haversine formula to calculate the distance between two lat/long coordinates
func haversineDistance(lat1, lon1, lat2, lon2 float64) float64 {
	var earthRadius float64 = 6371 // Earth radius in km

	latRad1 := lat1 * math.Pi / 180
	latRad2 := lat2 * math.Pi / 180

	difLat := (lat2 - lat1) * math.Pi / 180
	difLon := (lon2 - lon1) * math.Pi / 180

	a := math.Sin(difLat/2)*math.Sin(difLat/2) + math.Cos(latRad1)*math.Cos(latRad2)*math.Sin(difLon/2)*math.Sin(difLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	distance := earthRadius * c

	return distance
}

func (s *PostgresStore) DeliverToAddress(customerId int, addressId int) (*types.Deliverable, error) {
	var deliverable types.Deliverable

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback() // Rollback in case of panic
		}
	}()

	// Get the latitude and longitude of the customer's address
	var custLatitude, custLongitude float64
	err = tx.QueryRow(`SELECT latitude, longitude FROM address WHERE id = $1`, addressId).Scan(&custLatitude, &custLongitude)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// Get the latitude and longitude of the store
	var storeLatitude, storeLongitude float64
	// Assuming storeId is known, replace 'storeId' with actual store ID variable or parameter
	err = tx.QueryRow(`SELECT latitude, longitude FROM store WHERE id = $1`, 1).Scan(&storeLatitude, &storeLongitude)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// Calculate the distance using the Haversine formula
	distance := haversineDistance(custLatitude, custLongitude, storeLatitude, storeLongitude)

	// Check if the distance is within 1 km
	if distance <= 1 {
		deliverable.Deliverable = true
	} else {
		deliverable.Deliverable = false
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &deliverable, nil
}

func (s *PostgresStore) Delete_Address(customer_id int, address_id int) (*types.Address, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback() // Rollback in case of panic
		}
	}()

	// Fetch the address details before deleting it
	selectQuery := `SELECT id, customer_id, street_address, line_one_address, line_two_address, city, state, zipcode, is_default, latitude, longitude, created_at FROM address WHERE id=$1 AND customer_id=$2`
	row := tx.QueryRow(selectQuery, address_id, customer_id)

	address := &types.Address{}
	err = row.Scan(&address.Id, &address.Customer_Id, &address.Street_Address, &address.Line_One_Address, &address.Line_Two_Address, &address.City, &address.State, &address.Zipcode, &address.Is_Default, &address.Latitude, &address.Longitude, &address.Created_At)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// Delete the address
	deleteQuery := `DELETE FROM address WHERE id=$1 AND customer_id=$2`
	_, err = tx.Exec(deleteQuery, address_id, customer_id)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	// Commit the transaction if everything was successful
	err = tx.Commit()
	if err != nil {
		return nil, err
	}

	// Start a new transaction to set another address as is_default = true
	tx, err = s.db.Begin()
	if err != nil {
		return address, err
	}

	// Check if there is another address for the same customer_id
	selectDefaultQuery := `SELECT id FROM address WHERE customer_id=$1 AND is_default = false LIMIT 1`
	row = tx.QueryRow(selectDefaultQuery, customer_id)

	var newDefaultAddressID int
	if err := row.Scan(&newDefaultAddressID); err == nil {
		// Set the is_default value for the new default address to true
		updateDefaultQuery := `UPDATE address SET is_default=true WHERE id=$1`
		_, err = tx.Exec(updateDefaultQuery, newDefaultAddressID)
		if err != nil {
			tx.Rollback()
			return address, err
		}
	}

	// Commit the transaction for setting is_default = true
	err = tx.Commit()
	if err != nil {
		return address, err
	}

	return address, nil
}
