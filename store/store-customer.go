package store

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
	"github.com/google/uuid"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCustomerTable(tx *sql.Tx) error {
	// Updated table creation query with role column
	createTableQuery := `
        CREATE TABLE IF NOT EXISTS customer(
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            phone VARCHAR(10) UNIQUE NOT NULL,
            address TEXT NOT NULL,
            merchant_user_id VARCHAR(36) UNIQUE NULL CHECK (
                merchant_user_id IS NULL OR 
                (CHAR_LENGTH(merchant_user_id) <= 36 AND merchant_user_id ~ '^[A-Za-z0-9_-]*$')
            ),
            token UUID NULL,  
            role VARCHAR(20) NOT NULL DEFAULT 'Customer' CHECK (role IN ('Customer', 'Manager')), 
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );`

	_, err := tx.Exec(createTableQuery)
	if err != nil {
		return err // Return error if CREATE TABLE fails
	}

	// Check if the 'role' column exists and add it if not, along with the 'token' column check
	checkAndAlterQuery := `
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = 'customer' AND column_name = 'token'
            ) THEN
                ALTER TABLE customer ADD COLUMN token UUID NULL;
            END IF;

            IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = 'customer' AND column_name = 'role'
            ) THEN
                ALTER TABLE customer ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'Customer' CHECK (role IN ('Customer', 'Manager'));
            END IF;
        END
        $$;`

	_, err = tx.Exec(checkAndAlterQuery)
	if err != nil {
		return err // Return error if the check/alter operation fails
	}

	return nil // Return nil if everything succeeds
}

func (s *PostgresStore) GenMerchantUserId(cart_id int) (bool, error) {
	// Use sql.NullString to handle potential NULL values
	var merchantUserId sql.NullString

	checkQuery := `SELECT merchant_user_id FROM customer 
                   INNER JOIN shopping_cart ON customer.id = shopping_cart.customer_id 
                   WHERE shopping_cart.id = $1`
	err := s.db.QueryRow(checkQuery, cart_id).Scan(&merchantUserId)

	if err == sql.ErrNoRows {
		// cart_id not found, handle accordingly
		return false, err
	}

	if err != nil {
		// An error occurred during query execution
		return false, err
	}

	// Check if the merchantUserId is not NULL and not an empty string
	if merchantUserId.Valid && merchantUserId.String != "" {
		fmt.Println("merchant Id, ", merchantUserId.String)
		// Merchant User ID already exists
		return true, nil
	}

	// Generate a new UUID for merchant_user_id
	newMerchantUserId := uuid.New().String()

	// Update the customer record with the new merchant_user_id
	updateQuery := `UPDATE customer SET merchant_user_id = $1 
                    FROM shopping_cart 
                    WHERE customer.id = shopping_cart.customer_id 
                    AND shopping_cart.id = $2`
	_, updateErr := s.db.Exec(updateQuery, newMerchantUserId, cart_id)
	if updateErr != nil {
		return false, updateErr
	}

	return true, nil
}

func (s *PostgresStore) SendOtpMSG91(phone int) (*types.SendOTPResponse, error) {
	// Prepare the URL and headers
	if phone == 1234567890 {
		// Return a mock response
		return &types.SendOTPResponse{
			Type:      "test",
			RequestId: "test",
		}, nil
	}
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

func (s *PostgresStore) VerifyOtpMSG91(phone string, otp int) (*types.VerifyOTPResponse, error) {
	// Construct the URL with query parameters
	url := fmt.Sprintf("https://control.msg91.com/api/v5/otp/verify?mobile=91%s&otp=%d", phone, otp)

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
	var otpresponse types.VerifyOTPResponse
	if err := json.NewDecoder(resp.Body).Decode(&otpresponse); err != nil {
		return nil, err
	}

	// Check if OTP verification was successful
	if otpresponse.Type == "success" { // Replace `Success` with the actual field name indicating success in your `VerifyOTPResponse` struct
		// OTP verified successfully, proceed to fetch customer details
		var response types.CustomerLogin
		customerPtr, err := s.GetCustomerByPhone(phone)
		if err != nil {
			return nil, err
		}

		if customerPtr != nil {
			response.Customer = *customerPtr // Dereference the pointer
			response.Message = otpresponse.Message
			response.Type = otpresponse.Type
		} else {
			// handle the case where customer is not found, if necessary
		}
	} else {
		// OTP verification failed
		return nil, fmt.Errorf("OTP verification failed")
	}

	return nil, nil
}

func (s *PostgresStore) AuthenticateCustomer(phone string, token uuid.UUID) (bool, error) {
	// SQL query to check if there's a customer record matching the phone number and UUID token
	query := `
        SELECT EXISTS (
            SELECT 1 FROM customer
            WHERE phone = $1 AND token = $2
        );`

	var isAuthenticated bool
	// Execute the query, passing in the phone and token as parameters
	err := s.db.QueryRow(query, phone, token).Scan(&isAuthenticated)
	if err != nil {
		// If there's an error executing the query or scanning the result, return false and the error
		return false, err
	}

	// Return true if a matching record is found, false otherwise
	return isAuthenticated, nil
}

// Combined Create_Customer and Create_Shopping_Cart
func (s *PostgresStore) Create_Customer(user *types.Create_Customer) (*types.Customer_Login, error) {
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

	phoneNumberStr := user.Phone

	// Create the customer
	query := `INSERT INTO customer (name, phone, address) VALUES ($1, $2, $3) RETURNING id, name, phone, address, created_at, merchant_user_id`
	row := tx.QueryRow(query, "", phoneNumberStr, "")

	customer := &types.Customer_Login{}
	var merchantUserID sql.NullString

	err = row.Scan(
		&customer.ID,
		&customer.Name,
		&customer.Phone,
		&customer.Address,
		&customer.Created_At,
		&merchantUserID,
	)

	fmt.Println("II Row Scan Successful")

	if merchantUserID.Valid {
		customer.MerchantUserID = merchantUserID.String
	} else {
		customer.MerchantUserID = "" // or keep as a default value if needed
	}

	/*
		// Create the shopping cart
		query = `INSERT INTO shopping_cart (customer_id, active, store_id) VALUES ($1, $2, $3) RETURNING id, store_id`
		var cartId int
		err = tx.QueryRow(query, customer.ID, true, 1).Scan(&customer.Cart_Id, &customer.Store_Id)
		if err != nil {
			print(err)
			return nil, err
		}
		customer.Cart_Id = cartId
	*/

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		print(err)

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

func (s *PostgresStore) GetCustomerByPhone(phone string) (*types.Customer_Login, error) {
	fmt.Println("Started Get_Customer_By_Phone")
	query := `
        SELECT *
        FROM customer
        WHERE phone = $1
    `
	phoneNumberStr := phone

	row := s.db.QueryRow(query, phoneNumberStr)

	fmt.Println("I Query Successful")

	var customer types.Customer_Login
	var merchantUserID sql.NullString

	err := row.Scan(
		&customer.ID,
		&customer.Name,
		&customer.Phone,
		&customer.Address,
		&merchantUserID,
		&customer.Created_At,
	)

	fmt.Println("II Row Scan Successful")

	if merchantUserID.Valid {
		customer.MerchantUserID = merchantUserID.String
	} else {
		customer.MerchantUserID = "" // or keep as a default value if needed
	}

	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &customer, nil
}

func scan_Into_Customer(rows *sql.Rows) (*types.Customer, error) {
	customer := new(types.Customer)
	var merchantUserID sql.NullString // Use sql.NullString to handle NULL values

	err := rows.Scan(
		&customer.ID,
		&customer.Name,
		&customer.Phone,
		&customer.Address,
		&merchantUserID, // Scan into sql.NullString
		&customer.Created_At,
	)

	// Check if merchantUserID is valid, then assign its String value to customer.MerchantUserID
	if merchantUserID.Valid {
		customer.MerchantUserID = merchantUserID.String
	} else {
		customer.MerchantUserID = "" // or keep as a default value if needed
	}

	return customer, err
}
