package store

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
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

func (s *PostgresStore) SendOtpMSG91(phone int) (*types.SendOTPResponse, error) {
	// Prepare the URL and headers
	url := "https://control.msg91.com/api/v5/otp?template_id=6562ddc2d6fc0517bc535382&mobile=91" + fmt.Sprintf("%d", phone)
	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("accept", "application/json")
	req.Header.Set("authkey", "405982AVwwWkcR036562d3eaP1")
	req.Header.Set("content-type", "application/json")

	// Make the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// Decode the response
	var response types.SendOTPResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, err
	}

	return &response, nil
}

func (s *PostgresStore) VerifyOtpMSG91(phone int, otp int) (*types.VerifyOTPResponse, error) {
	// Construct the URL with query parameters
	url := fmt.Sprintf("https://control.msg91.com/api/v5/otp/verify?mobile=91%d&otp=%d", phone, otp)

	// Create a new request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	// Set headers
	req.Header.Set("accept", "application/json")
	req.Header.Set("authkey", "405982AVwwWkcR036562d3eaP1")

	// Initialize HTTP client and send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// Parse the JSON response
	var response types.VerifyOTPResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, err
	}

	return &response, nil
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
