package store

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/girithc/pronto-go/types"
	"github.com/google/uuid"
)

func (s *PostgresStore) CreatePackerTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS packer(
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        phone VARCHAR(10) UNIQUE NOT NULL, 
		token UUID NULL,  
		fcm TEXT NULL,
		role VARCHAR(20) NOT NULL DEFAULT 'Customer' CHECK (role IN ('Customer', 'Manager')), 
        address TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating packer table: %w", err)
	}

	// Check if the 'role' column exists and add it if not, along with the 'token' column check
	checkAndAlterQuery := `
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = 'packer' AND column_name = 'token'
            ) THEN
                ALTER TABLE packer ADD COLUMN token UUID NULL;
            END IF;

            IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = 'packer' AND column_name = 'role'
            ) THEN
                ALTER TABLE packer ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'Customer' CHECK (role IN ('Customer', 'Manager'));
            END IF;

			IF NOT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = 'packer' AND column_name = 'fcm'
            ) THEN
                ALTER TABLE packer ADD COLUMN fcm TEXT UNIQUE NULL;
            END IF;
        END
        $$;`

	_, err = tx.Exec(checkAndAlterQuery)
	if err != nil {
		return err
	}

	return nil
}

func (s *PostgresStore) CreatePacker(phone string) (*Packer, error) {
	// Query to check if a packer already exists with the given phone number
	checkQuery := `SELECT id, name, phone, address, created_at FROM packer WHERE phone = $1`

	var existingPacker Packer
	err := s.db.QueryRow(checkQuery, phone).Scan(&existingPacker.ID, &existingPacker.Name, &existingPacker.Phone, &existingPacker.Address, &existingPacker.CreatedAt)

	// If a packer is found, return their details
	if err == nil {
		return &existingPacker, nil
	}

	// If no existing packer was found, create a new one
	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing packer: %w", err)
	}

	// SQL query to insert a new packer and return its details
	insertQuery := `
        INSERT INTO packer (name, phone, address)
        VALUES ('', $1, '')
        RETURNING id, name, phone, address, created_at;
    `

	var newPacker Packer
	err = s.db.QueryRow(insertQuery, phone).Scan(&newPacker.ID, &newPacker.Name, &newPacker.Phone, &newPacker.Address, &newPacker.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("error creating new packer: %w %s", err, phone)
	}

	return &newPacker, nil
}

// Packer represents the structure of a packer in the database
type Packer struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Phone     string    `json:"phone"`
	Address   string    `json:"address"`
	CreatedAt time.Time `json:"created_at"`
}

func (s *PostgresStore) PackerAcceptOrder(cart_id int, phone string) error {
	// First, get the packer_id based on the phone number
	var packerID int
	getPackerIDQuery := `SELECT id FROM packer WHERE phone = $1;`
	err := s.db.QueryRow(getPackerIDQuery, phone).Scan(&packerID)
	if err != nil {
		return fmt.Errorf("error finding packer: %w", err)
	}

	// Check if the current order_status is 'received'
	var currentStatus string
	statusCheckQuery := `SELECT order_status FROM sales_order WHERE cart_id = $1;`
	err = s.db.QueryRow(statusCheckQuery, cart_id).Scan(&currentStatus)
	if err != nil {
		return fmt.Errorf("error checking order status: %w", err)
	}
	if currentStatus != "received" {
		return fmt.Errorf("order status is not 'received'; current status: %s", currentStatus)
	}

	// Then, assign the packer to the order with the given cart_id and update the order status to 'accepted'
	assignPackerQuery := `
    UPDATE sales_order
    SET packer_id = $1, order_status = 'accepted'
    WHERE cart_id = $2 AND packer_id IS NULL;` // Ensuring that no packer is already assigned

	_, err = s.db.Exec(assignPackerQuery, packerID, cart_id)
	if err != nil {
		return fmt.Errorf("error assigning packer to order and updating status: %w", err)
	}

	return nil
}

func (s *PostgresStore) PackerPackOrder(cart_id int, phone string) error {
	// First, get the packer_id based on the phone number
	var packerID int
	getPackerIDQuery := `SELECT id FROM packer WHERE phone = $1;`
	err := s.db.QueryRow(getPackerIDQuery, phone).Scan(&packerID)
	if err != nil {
		return fmt.Errorf("error finding packer: %w", err)
	}

	// Check if the current order_status is 'accepted'
	var currentStatus string
	var orderId int
	statusCheckQuery := `SELECT id, order_status FROM sales_order WHERE cart_id = $1;`
	err = s.db.QueryRow(statusCheckQuery, cart_id).Scan(&orderId, &currentStatus)
	if err != nil {
		return fmt.Errorf("error checking order status: %w", err)
	}
	if currentStatus != "accepted" {
		return fmt.Errorf("order cannot be packed; current status: %s", currentStatus)
	}

	// Then, update the order status to 'packed'
	packOrderQuery := `
    UPDATE sales_order
    SET order_status = 'packed', packer_id = $1
    WHERE cart_id = $2 AND id = $3;`

	_, err = s.db.Exec(packOrderQuery, packerID, cart_id, orderId)
	if err != nil {
		return fmt.Errorf("error updating order status to 'packed': %w", err)
	}

	return nil
}

func (s *PostgresStore) SendOtpPackerMSG91(phone string) (*types.SendOTPResponse, error) {
	// Prepare the URL and headers
	if phone == "1234567890" {
		// Return a mock response
		return &types.SendOTPResponse{
			Type:      "test",
			RequestId: "test",
		}, nil
	}
	phoneInt, err := strconv.Atoi(phone)
	if err != nil {
		// Handle error if the phone number is not a valid integer
		return nil, err
	}

	url := "https://control.msg91.com/api/v5/otp?template_id=6562ddc2d6fc0517bc535382&mobile=91" + fmt.Sprintf("%d", phoneInt)
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

func (s *PostgresStore) VerifyOtpPackerMSG91(phone string, otp int, fcm string) (*types.PackerLogin, error) {
	// Construct the URL with query parameters

	if phone == "1234567890" {
		var response types.PackerLogin
		var otpresponse types.VerifyOTPResponse
		otpresponse.Type = "success"
		otpresponse.Message = "test user - OTP verified successfully"
		packerPtr, err := s.GetPackerByPhone(phone, fcm)
		if err != nil {
			return nil, err
		}

		response.Packer = *packerPtr // Dereference the pointer
		response.Message = otpresponse.Message
		response.Type = otpresponse.Type
		return &response, nil
	}

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
		var response types.PackerLogin
		packerPtr, err := s.GetPackerByPhone(phone, fcm)
		if err != nil {
			return nil, err
		}

		response.Packer = *packerPtr // Dereference the pointer
		response.Message = otpresponse.Message
		response.Type = otpresponse.Type
		return &response, nil
	} else {
		// OTP verification failed
		return nil, fmt.Errorf("OTP verification failed")
	}
}

func (s *PostgresStore) AuthenticatePacker(phone string, token uuid.UUID) (bool, error) {
	// SQL query to check if there's a customer record matching the phone number and UUID token
	query := `
        SELECT EXISTS (
            SELECT 1 FROM packer
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

func (s *PostgresStore) GetPackerByPhone(phone string, fcm string) (*types.PackerData, error) {
	fmt.Println("Started GetPackerByPhone")

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // Ensure rollback in case of failure

	// Clear FCM for any packer that might have it
	clearFCMSQL := `UPDATE packer SET fcm = NULL WHERE fcm = $1`
	if _, err := tx.Exec(clearFCMSQL, fcm); err != nil {
		return nil, err
	}

	// Update FCM for the packer with the given phone and fetch necessary fields
	updateFCMSQL := `
        UPDATE packer 
        SET fcm = $1 
        WHERE phone = $2 
        RETURNING id, name, phone, address, created_at, token`
	row := tx.QueryRow(updateFCMSQL, fcm, phone)

	var packer types.PackerData
	var token sql.NullString

	err = row.Scan(
		&packer.ID,
		&packer.Name,
		&packer.Phone,
		&packer.Address,
		&packer.Created_At,
		&token,
	)

	if err == sql.ErrNoRows {
		newToken, _ := uuid.NewUUID() // Generate a new UUID for the token
		insertSQL := `
            INSERT INTO packer (name, phone, address, token, fcm)
            VALUES ('', $1, '', $2, $3)
            RETURNING id, name, phone, address, created_at, token`
		row = tx.QueryRow(insertSQL, phone, newToken, fcm)

		// Scan the new customer data
		err = row.Scan(
			&packer.ID,
			&packer.Name,
			&packer.Phone,
			&packer.Address,
			&packer.Created_At,
			&token,
		)
		if err != nil {
			return nil, err
		}
		packer.Token = newToken
	} else if err != nil {
		return nil, err
	}

	// Check if token needs to be generated
	if !token.Valid || token.String == "" {
		newToken, _ := uuid.NewUUID() // Generate a new UUID for the token
		updateTokenSQL := `UPDATE packer SET token = $1 WHERE id = $2`
		if _, err := tx.Exec(updateTokenSQL, newToken, packer.ID); err != nil {
			return nil, err
		}
		packer.Token = newToken // Set the newly generated token in the packer object
	} else {
		packer.Token = uuid.MustParse(token.String) // Use the existing token if valid
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	fmt.Println("Transaction Successful")
	return &packer, nil
}
