package store

import (
	"database/sql"
	"fmt"
	"strconv"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCustomerTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateCustomerTable")

	query := `create table if not exists customer(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		phone VARCHAR(10) UNIQUE NOT NULL, 
		address TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := tx.Exec(query)

	// fmt.Println("Exiting CreateCustomerTable")

	return err
}

// Combined Create_Customer and Create_Shopping_Cart
func (s *PostgresStore) Create_Customer(user *types.Create_Customer) (*types.Customer_With_Cart, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			tx.Commit()
		}
	}()

	phoneNumberStr := strconv.Itoa(user.Phone)

	// Create the customer
	query := `INSERT INTO customer (name, phone, address) VALUES ($1, $2, $3) RETURNING id, name, phone, address, created_at`
	row := tx.QueryRow(query, "", phoneNumberStr, "")

	customer := &types.Customer_With_Cart{}
	err = row.Scan(&customer.ID, &customer.Name, &customer.Phone, &customer.Address, &customer.Created_At)
	if err != nil {
		return nil, err
	}

	// Create the shopping cart
	query = `INSERT INTO shopping_cart (customer_id, active) VALUES ($1, $2) RETURNING id`
	var cartId int
	err = tx.QueryRow(query, customer.ID, true).Scan(&cartId)
	if err != nil {
		return nil, err
	}
	customer.Cart_Id = cartId

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return customer, nil
}

func (s *PostgresStore) Get_All_Customers() ([]*types.Customer, error) {
	query := `select * from customer
	`
	rows, err := s.db.Query(
		query)
	if err != nil {
		return nil, err
	}

	customers := []*types.Customer{}

	for rows.Next() {
		customer, err := scan_Into_Customer(rows)
		if err != nil {
			return nil, err
		}
		customers = append(customers, customer)
	}

	return customers, nil
}

func (s *PostgresStore) Get_Customer_By_Phone(phone int) (*types.Customer_With_Cart, error) {
	fmt.Println("Started Get_Customer_By_Phone")
	query := `
        SELECT c.*, sc.id AS shopping_cart_id, sc.store_id
        FROM customer c
        LEFT JOIN shopping_cart sc ON c.id = sc.customer_id AND sc.active = true
        WHERE c.phone = $1
    `
	phoneNumberStr := strconv.Itoa(phone)

	row := s.db.QueryRow(query, phoneNumberStr)

	fmt.Println("I Query Successful")

	var customer types.Customer_With_Cart
	var storeID sql.NullInt64 // using NullInt64 for store_id

	err := row.Scan(
		&customer.ID,
		&customer.Name,
		&customer.Phone,
		&customer.Address,
		&customer.Created_At,
		&customer.Cart_Id,
		&storeID,
	)

	fmt.Println("II Row Scan Successful")

	if storeID.Valid {
		customer.Store_Id = int(storeID.Int64) // If not null, assign to customer.Store_Id
	}

	switch {
	case err == sql.ErrNoRows:
		return nil, nil
	case err != nil:
		return nil, err
	}

	return &customer, nil
}

// Helper
func scan_Into_Customer(rows *sql.Rows) (*types.Customer, error) {
	customer := new(types.Customer)
	err := rows.Scan(
		&customer.ID,
		&customer.Name,
		&customer.Phone,
		&customer.Address,
		&customer.Created_At,
	)

	return customer, err
}
