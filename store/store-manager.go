package store

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/girithc/pronto-go/types"
	"github.com/google/uuid"
)

func (s *PostgresStore) CreateManagerTable(tx *sql.Tx) error {
	query := `CREATE TABLE IF NOT EXISTS manager (
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) DEFAULT '',
		phone VARCHAR(10) UNIQUE NOT NULL,
		token UUID NULL,  
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	);`
	_, err := tx.Exec(query)
	if err != nil {
		return err
	}
	return nil
}

func (s *PostgresStore) SendOtpManagerMSG91(phone string) (*types.SendOTPResponse, error) {
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

func (s *PostgresStore) VerifyOtpManagerMSG91(phone string, otp int, fcm string) (*types.ManagerLogin, error) {
	// Construct the URL with query parameters

	if phone == "1234567890" {
		var response types.ManagerLogin
		var otpresponse types.VerifyOTPResponse
		otpresponse.Type = "success"
		otpresponse.Message = "test user - OTP verified successfully"
		managerPtr, err := s.GetManagerByPhone(phone, fcm)
		if err != nil {
			return nil, err
		}

		response.Manager = *managerPtr // Dereference the pointer
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
		var response types.ManagerLogin
		managerPtr, err := s.GetManagerByPhone(phone, fcm)
		if err != nil {
			return nil, err
		}

		response.Manager = *managerPtr // Dereference the pointer
		response.Message = otpresponse.Message
		response.Type = otpresponse.Type
		return &response, nil
	} else {
		// OTP verification failed
		return nil, fmt.Errorf("OTP verification failed")
	}
}

func (s *PostgresStore) AuthenticateManager(phone string, token uuid.UUID) (bool, error) {
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

func (s *PostgresStore) GetManagerByPhone(phone string, fcm string) (*types.ManagerData, error) {
	fmt.Println("Started GetManagerByPhone")

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // Ensure rollback in case of failure

	// Update FCM for the manager with the given phone and fetch necessary fields
	updateSQL := `
        SELECT id, name, phone, created_at, token from manager
        WHERE phone = $1`
	row := tx.QueryRow(updateSQL, phone)

	var manager types.ManagerData
	var token sql.NullString

	err = row.Scan(
		&manager.ID,
		&manager.Name,
		&manager.Phone,
		&manager.Created_At,
		&token,
	)

	if err == sql.ErrNoRows {
		newToken, _ := uuid.NewUUID() // Generate a new UUID for the token
		insertSQL := `
            INSERT INTO manager (name, phone, token)
            VALUES ('', $1, $2)
            RETURNING id, name, phone, created_at, token`
		row = tx.QueryRow(insertSQL, phone, newToken)

		// Scan the new manager data
		err = row.Scan(
			&manager.ID,
			&manager.Name,
			&manager.Phone,
			&manager.Created_At,
			&token,
		)
		if err != nil {
			return nil, err
		}
		manager.Token = newToken
	} else if err != nil {
		return nil, err
	}

	// Check if token needs to be generated
	if !token.Valid || token.String == "" {
		newToken, _ := uuid.NewUUID() // Generate a new UUID for the token
		updateTokenSQL := `UPDATE manager SET token = $1 WHERE id = $2`
		if _, err := tx.Exec(updateTokenSQL, newToken, manager.ID); err != nil {
			return nil, err
		}
		manager.Token = newToken // Set the newly generated token in the manager object
	} else {
		manager.Token = uuid.MustParse(token.String) // Use the existing token if valid
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	fmt.Println("Transaction Successful")
	return &manager, nil
}

func (s *PostgresStore) AuthenticateRequestManager(phone, token string) (bool, error) {
	query := `SELECT token FROM manager WHERE phone = $1`

	var dbToken sql.NullString

	err := s.db.QueryRow(query, phone).Scan(&dbToken)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, nil
		}
		return false, err
	}

	if dbToken.Valid && dbToken.String == token {
		return true, nil
	}

	return false, nil
}

func (s *PostgresStore) ManagerItemStoreCombo() (bool, error) {
	// Retrieve all items
	itemsQuery := `SELECT id FROM item`
	rows, err := s.db.Query(itemsQuery)
	if err != nil {
		return false, fmt.Errorf("error retrieving items: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var itemID int
		if err := rows.Scan(&itemID); err != nil {
			return false, fmt.Errorf("error scanning item ID: %w", err)
		}

		// Check if the item already exists in item_store
		var exists bool
		checkQuery := `SELECT EXISTS(SELECT 1 FROM item_store WHERE item_id = $1)`
		if err := s.db.QueryRow(checkQuery, itemID).Scan(&exists); err != nil {
			return false, fmt.Errorf("error checking item_store: %w", err)
		}

		if !exists {
			// Get mrp_price from item_financial, if available
			var mrpPrice float64
			financialQuery := `SELECT mrp_price FROM item_financial WHERE item_id = $1`
			err := s.db.QueryRow(financialQuery, itemID).Scan(&mrpPrice)
			if err != nil {
				// If there's no financial record, default mrpPrice to 0
				mrpPrice = 0
			}

			// Insert a new record into item_store
			insertQuery := `INSERT INTO item_store (item_id, store_price, discount, stock_quantity, store_id) VALUES ($1, $2, 0, 0, 1)` // Assuming store_id is 1 for simplicity
			if _, err := s.db.Exec(insertQuery, itemID, mrpPrice); err != nil {
				return false, fmt.Errorf("error inserting into item_store: %w", err)
			}
		}
	}

	return true, nil
}

func (s *PostgresStore) ManagerAddNewItem(item types.ItemBasic) (types.ItemBasicReturn, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return types.ItemBasicReturn{}, fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback() // Ensure rollback in case of failure

	// Verify if the brand exists
	var exists bool
	err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM brand WHERE id = $1)", item.BrandId).Scan(&exists)
	if err != nil {
		return types.ItemBasicReturn{}, fmt.Errorf("failed to query brand existence: %w", err)
	}
	if !exists {
		return types.ItemBasicReturn{}, fmt.Errorf("brand with ID %d does not exist", item.BrandId)
	}

	// Insert the item
	insertQuery := `
        INSERT INTO item (name, brand_id, quantity, unit_of_quantity, description)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id;`
	var itemId int
	err = tx.QueryRow(insertQuery, item.Name, item.BrandId, item.Quantity, item.UnitOfQuantity, item.Description).Scan(&itemId)
	if err != nil {
		return types.ItemBasicReturn{}, fmt.Errorf("failed to insert item: %w", err)
	}

	// Retrieve category IDs from category names
	var categoryIds []int
	for _, categoryName := range item.CategoryNames {
		var categoryId int
		err = tx.QueryRow("SELECT id FROM category WHERE name = $1", categoryName).Scan(&categoryId)
		if err != nil {
			return types.ItemBasicReturn{}, fmt.Errorf("failed to retrieve category ID for %s: %w", categoryName, err)
		}
		categoryIds = append(categoryIds, categoryId)
	}

	// Insert into item_category table for each category ID
	for _, categoryId := range categoryIds {
		_, err = tx.Exec("INSERT INTO item_category (item_id, category_id) VALUES ($1, $2)", itemId, categoryId)
		if err != nil {
			return types.ItemBasicReturn{}, fmt.Errorf("failed to insert into item_category: %w", err)
		}
	}

	// Commit the transaction
	if err = tx.Commit(); err != nil {
		return types.ItemBasicReturn{}, fmt.Errorf("failed to commit transaction: %w", err)
	}

	// Return the inserted item with category names
	return types.ItemBasicReturn{
		Name:           item.Name,
		BrandId:        item.BrandId,
		Quantity:       item.Quantity,
		UnitOfQuantity: item.UnitOfQuantity,
		Description:    item.Description,
		CategoryNames:  item.CategoryNames,
		Id:             itemId,
	}, nil
}
