package store

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/girithc/pronto-go/types"
	"github.com/google/uuid"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateDeliveryPartnerTable(tx *sql.Tx) error {
	query := `
	create table if not exists delivery_partner(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		fcm TEXT NULL,  
		role VARCHAR(20) NOT NULL DEFAULT 'Customer' CHECK (role IN ('Customer', 'Manager')), 
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		phone VARCHAR(10) NOT NULL, 
		address TEXT NOT NULL,
		available BOOLEAN DEFAULT true,
		current_location TEXT, 
		active_deliveries INT DEFAULT 0,
		last_assigned_time TIMESTAMP DEFAULT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := tx.Exec(query)
	if err != nil {
		return err
	}

	// Check if the 'role' column exists and add it if not, along with the 'token' column check
	checkAndAlterQuery := `
	DO $$
	BEGIN
		IF NOT EXISTS (
			SELECT FROM information_schema.columns 
			WHERE table_name = 'delivery_partner' AND column_name = 'token'
		) THEN
			ALTER TABLE delivery_partner ADD COLUMN token UUID NULL;
		END IF;

		IF NOT EXISTS (
			SELECT FROM information_schema.columns 
			WHERE table_name = 'delivery_partner' AND column_name = 'role'
		) THEN
			ALTER TABLE delivery_partner ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'Customer' CHECK (role IN ('Customer', 'Manager'));
		END IF;

		IF NOT EXISTS (
			SELECT FROM information_schema.columns 
			WHERE table_name = 'delivery_partner' AND column_name = 'fcm'
		) THEN
			ALTER TABLE delivery_partner ADD COLUMN fcm TEXT UNIQUE NULL;
		END IF;
	END
	$$;`

	_, err = tx.Exec(checkAndAlterQuery)
	if err != nil {
		return err
	}

	return err
}

// 1. Create a function to insert a new delivery partner
func (s *PostgresStore) Create_Delivery_Partner(dp *types.Create_Delivery_Partner) (*types.Delivery_Partner, error) {
	query := `
		INSERT INTO delivery_partner
		(name, phone, address, fcm_token, store_id) 
		VALUES ($1, $2, $3, $4, $5) 
		RETURNING id, name, fcm_token, store_id, phone, address, created_at
	`

	rows, err := s.db.Query(
		query,
		dp.Name,
		dp.Phone,
		"", // empty address for this example
		"", // empty fcm_token for this example
		dp.Store_ID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.Delivery_Partner{}
	for rows.Next() {
		partner, err := scan_Into_Delivery_Partner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}

	if len(partners) == 0 {
		return nil, fmt.Errorf("no delivery partner was created")
	}

	return partners[0], nil
}

func (s *PostgresStore) GetFirstAssignedOrder(phone string) (*OrderAssigned, error) {
	// Define the query
	query := `
        SELECT so.id, so.delivery_partner_id, so.store_id,
               so.order_date, so.order_status, so.order_dp_status
        FROM sales_order so
        JOIN delivery_partner dp ON so.delivery_partner_id = dp.id
        WHERE dp.phone = $1 AND so.order_status != 'completed'
        ORDER BY so.order_date ASC
        LIMIT 1
    `

	// Variable to hold the order details
	order := &OrderAssigned{}

	// Execute the query
	err := s.db.QueryRow(query, phone).Scan(&order.ID, &order.DeliveryPartnerID, &order.StoreID, &order.OrderDate, &order.OrderStatus, &order.DeliveryPartnerStatus)
	if err != nil {
		if err == sql.ErrNoRows {
			// No order assigned, attempt to assign an order
			cartID, err := s.GetOldestUnassignedOrder()
			if err != nil {
				return nil, err
			}
			if cartID > 0 {
				assigned, assignErr := s.AssignDeliveryPartnerToSalesOrder(cartID, phone)
				if assigned && assignErr == nil {
					// Fetch the newly assigned order
					query := `
				SELECT so.id, so.delivery_partner_id, so.store_id,
					so.order_date, so.order_status, so.order_dp_status
				FROM sales_order so
				JOIN delivery_partner dp ON so.delivery_partner_id = dp.id
				WHERE dp.phone = $1
				ORDER BY so.order_date ASC
				LIMIT 1
    `

					// Variable to hold the order details
					order := &OrderAssigned{}
					err := s.db.QueryRow(query, phone).Scan(&order.ID, &order.DeliveryPartnerID, &order.StoreID, &order.OrderDate, &order.OrderStatus, &order.DeliveryPartnerStatus)
					if err != nil {
						return nil, err
					}
					return order, nil
				}

				return nil, assignErr
			}
			return nil, nil

		}
		return nil, err
	}

	return order, nil
}

type OrderAssigned struct {
	ID                    int       `json:"id"`
	DeliveryPartnerID     int       `json:"delivery_partner_id"`
	StoreID               int       `json:"store_id"`
	OrderDate             time.Time `json:"order_date"`
	OrderStatus           string    `json:"order_status"`
	DeliveryPartnerStatus string    `json:"order_dp_status"`
}
type OrderAccepted_DP struct {
	ID                    int       `json:"id"`
	DeliveryPartnerID     int       `json:"delivery_partner_id"`
	StoreID               int       `json:"store_id"`
	StoreName             string    `json:"store_name"`
	StoreAddress          string    `json:"store_address"`
	OrderDate             time.Time `json:"order_date"`
	OrderStatus           string    `json:"order_status"`
	DeliveryPartnerStatus string    `json:"order_dp_status"`
	CustomerPhone         string    `json:"customer_phone"`
}

func (s *PostgresStore) DeliveryPartnerAcceptOrder(phone string, order_id int) (*OrderAccepted_DP, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Get delivery partner ID from phone number
	var deliveryPartnerID int
	err = tx.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	// Verify that the delivery partner assigned is the one making the request
	var existingDeliveryPartnerID sql.NullInt64 // Using sql.NullInt64 to handle null values
	err = tx.QueryRow(`SELECT delivery_partner_id FROM sales_order WHERE id = $1;`, order_id).Scan(&existingDeliveryPartnerID)
	if err != nil {
		return nil, err
	}
	if !existingDeliveryPartnerID.Valid || existingDeliveryPartnerID.Int64 != int64(deliveryPartnerID) {
		return nil, fmt.Errorf("order is not assigned to this delivery partner")
	}

	// Update the sales_order status to 'accepted'
	var storeID int
	var orderDate time.Time
	var orderStatus, orderDPStatus string
	err = tx.QueryRow(`
    UPDATE sales_order
    SET order_dp_status = 'accepted'
    WHERE id = $1 AND (order_dp_status = 'pending' OR delivery_partner_id = $2)
    RETURNING store_id, order_date, order_status, order_dp_status;`, order_id, deliveryPartnerID).Scan(&storeID, &orderDate, &orderStatus, &orderDPStatus)
	if err != nil {
		return nil, err
	}

	// Check for an existing delivery_order record
	var existingDeliveryOrderID int
	err = tx.QueryRow(`SELECT id FROM delivery_order WHERE sales_order_id = $1 AND delivery_partner_id = $2;`, order_id, deliveryPartnerID).Scan(&existingDeliveryOrderID)

	// Update or insert delivery_order record
	if err == sql.ErrNoRows {
		// Insert a new delivery_order record with order_accepted_date as current timestamp
		_, err = tx.Exec(`
            INSERT INTO delivery_order (sales_order_id, delivery_partner_id, order_accepted_date)
            VALUES ($1, $2, CURRENT_TIMESTAMP);`, order_id, deliveryPartnerID)
		if err != nil {
			return nil, err
		}
	} else if err == nil {
		// Update the existing record's order_accepted_date
		_, err = tx.Exec(`
            UPDATE delivery_order
            SET order_accepted_date = CURRENT_TIMESTAMP
            WHERE id = $1;`, existingDeliveryOrderID)
		if err != nil {
			return nil, err
		}
	} else {
		return nil, err
	}

	// Commit the transaction
	if err = tx.Commit(); err != nil {
		return nil, err
	}

	// Fetch store details
	var storeName, storeAddress string
	err = s.db.QueryRow(`SELECT name, address FROM store WHERE id = $1;`, storeID).Scan(&storeName, &storeAddress)
	if err != nil {
		return nil, err
	}

	if orderStatus == "arrived" {
		var customerPhone string

		// Get customer_id from sales_order table
		var customerID int
		err = s.db.QueryRow(`SELECT customer_id FROM sales_order WHERE id = $1;`, order_id).Scan(&customerID)
		if err != nil {
			return nil, err
		}

		// Get phone from customer table using customer_id
		err = s.db.QueryRow(`SELECT phone FROM customer WHERE id = $1;`, customerID).Scan(&customerPhone)
		if err != nil {
			return nil, err
		}

		// Create and return the accepted order details
		acceptedOrder := &OrderAccepted_DP{
			ID:                    order_id,
			DeliveryPartnerID:     deliveryPartnerID,
			StoreID:               storeID,
			StoreName:             storeName,
			StoreAddress:          storeAddress,
			OrderDate:             orderDate,
			OrderStatus:           orderStatus,
			DeliveryPartnerStatus: orderDPStatus,
			CustomerPhone:         customerPhone,
		}

		return acceptedOrder, nil

	} else {
		// Create and return the accepted order details
		acceptedOrder := &OrderAccepted_DP{
			ID:                    order_id,
			DeliveryPartnerID:     deliveryPartnerID,
			StoreID:               storeID,
			StoreName:             storeName,
			StoreAddress:          storeAddress,
			OrderDate:             orderDate,
			OrderStatus:           orderStatus,
			DeliveryPartnerStatus: orderDPStatus,
			CustomerPhone:         "",
		}
		return acceptedOrder, nil

	}
}

type PickupOrderInfo struct {
	CustomerName    string    `json:"customer_name"`
	CustomerPhone   string    `json:"customer_phone"`
	Latitude        float64   `json:"latitude"`
	Longitude       float64   `json:"longitude"`
	LineOneAddress  string    `json:"line_one_address"`
	LineTwoAddress  string    `json:"line_two_address"`
	StreetAddress   string    `json:"street_address"`
	OrderDate       time.Time `json:"order_date"`
	OrderStatus     string    `json:"order_status"`
	AmountToCollect int       `json:"amount_to_collect"`
}

func (s *PostgresStore) DeliveryPartnerPickupOrder(phone string, order_id int) (*PickupOrderInfo, error) {
	var info PickupOrderInfo

	// Get delivery partner ID from phone number
	var deliveryPartnerID int
	err := s.db.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	orderQuery := `
    SELECT c.name, c.phone, so.order_date, so.order_status,
           COALESCE(sc.address_id, so.address_id) AS address_id, t.amount
    FROM sales_order so
    LEFT JOIN shopping_cart sc ON so.cart_id = sc.id
    INNER JOIN customer c ON so.customer_id = c.id
    LEFT JOIN transaction t ON so.transaction_id = t.id
    WHERE so.id = $1 AND so.delivery_partner_id = $2 AND so.order_dp_status = 'accepted' AND so.order_status != 'completed';`

	var addressID int
	err = s.db.QueryRow(orderQuery, order_id, deliveryPartnerID).Scan(&info.CustomerName, &info.CustomerPhone, &info.OrderDate, &info.OrderStatus, &addressID, &info.AmountToCollect)
	if err != nil {
		return nil, err
	}

	// Query to get address information using the obtained addressID
	addressQuery := `SELECT latitude, longitude, line_one_address, line_two_address, street_address FROM address WHERE id = $1;`
	err = s.db.QueryRow(addressQuery, addressID).Scan(&info.Latitude, &info.Longitude, &info.LineOneAddress, &info.LineTwoAddress, &info.StreetAddress)
	if err != nil {
		return nil, err
	}

	// Evaluate order status
	switch info.OrderStatus {
	case "dispatched":
		// Return the information for dispatched orders
		println("Order Dispatched")
		return &info, nil
	case "packed":
		// Return nil for packed orders as they are not yet ready for pickup
		println("Order Not Dispatched")
		return nil, nil
	default:
		// For any other status, return an error indicating the order is not ready for pickup
		return nil, &OrderStatusError{Status: info.OrderStatus}
	}
}

func (s *PostgresStore) DeliveryPartnerDispatchOrder(phone string, order_id int) (*DeliveryPartnerDispatchResult, error) {
	var location int

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // Ensure transaction is rolled back in case of error

	// Verify the sales order's current status is 'packed'
	var currentStatus string
	err = tx.QueryRow("SELECT order_status FROM sales_order WHERE id = $1", order_id).Scan(&currentStatus)
	if err != nil {
		return nil, err
	}
	if currentStatus != "packed" {
		return nil, errors.New("order is not in packed status")
	}

	// Retrieve the location from delivery_shelf for the given order_id
	err = tx.QueryRow("SELECT location FROM delivery_shelf WHERE order_id = $1 LIMIT 1", order_id).Scan(&location)
	if err != nil {
		// Handle the error if the location is not found or any other database error occurs
		return nil, err
	}

	// Verify the delivery partner ID and retrieve delivery partner name
	var deliveryPartnerName string
	var deliveryPartnerIDFromDB int
	err = tx.QueryRow("SELECT id, name FROM delivery_partner WHERE phone = $1", phone).Scan(&deliveryPartnerIDFromDB, &deliveryPartnerName)
	if err != nil {
		return nil, err
	}

	// Update the order_status to 'dispatched' in sales_order
	_, err = tx.Exec("UPDATE sales_order SET order_status = 'dispatched' WHERE id = $1 AND delivery_partner_id = $2 AND order_status != 'completed'", order_id, deliveryPartnerIDFromDB)
	if err != nil {
		return nil, err
	}

	// Remove the sales_order_id from delivery_shelf for the given order_id
	_, err = tx.Exec("UPDATE delivery_shelf SET order_id = NULL WHERE order_id = $1", order_id)
	if err != nil {
		return nil, err
	}

	// Update the pickup_time and set active to false in packer_shelf for the associated sales_order_id
	_, err = tx.Exec("UPDATE packer_shelf SET pickup_time = CURRENT_TIMESTAMP, active = false WHERE sales_order_id = $1", order_id)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	// Return the dispatch result
	result := &DeliveryPartnerDispatchResult{
		DeliveryPartnerName: deliveryPartnerName,
		SalesOrderID:        order_id,
		OrderStatus:         "dispatched",
		Location:            location,
	}

	return result, nil
}

func (s *PostgresStore) DeliveryPartnerArrive(phone string, order_id int, status string) (*DeliveryPartnerArriveResult, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Verify the sales order's current status is 'dispatched'
	var currentStatus string
	err = tx.QueryRow("SELECT order_status FROM sales_order WHERE id = $1", order_id).Scan(&currentStatus)
	if err != nil {
		return nil, err
	}
	if currentStatus != "dispatched" {
		return nil, errors.New("order is not in dispatched status")
	}

	// Verify the delivery partner ID and retrieve delivery partner name
	var deliveryPartnerName string
	var deliveryPartnerIDFromDB int
	err = tx.QueryRow("SELECT id, name FROM delivery_partner WHERE phone = $1", phone).Scan(&deliveryPartnerIDFromDB, &deliveryPartnerName)
	if err != nil {
		return nil, err
	}

	// Update the order_status to 'arrived' in sales_order
	_, err = tx.Exec("UPDATE sales_order SET order_status = $1 WHERE id = $2 AND delivery_partner_id = $3", status, order_id, deliveryPartnerIDFromDB)
	if err != nil {
		return nil, err
	}

	// Update the delivery_order record with order_arrive_date as current timestamp
	_, err = tx.Exec(`
        UPDATE delivery_order
        SET order_arrive_date = CURRENT_TIMESTAMP
        WHERE sales_order_id = $1 AND delivery_partner_id = $2;`, order_id, deliveryPartnerIDFromDB)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	// Prepare and return the arrival result
	result := &DeliveryPartnerArriveResult{
		SalesOrderID: order_id,
		OrderStatus:  status,
	}

	return result, nil
}

func (s *PostgresStore) DeliveryPartnerCompleteOrderDelivery(phone string, order_id int, image string) (*DeliveryCompletionResult, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Verify the delivery partner ID
	var deliveryPartnerIDFromDB int
	err = tx.QueryRow("SELECT id FROM delivery_partner WHERE phone = $1", phone).Scan(&deliveryPartnerIDFromDB)
	if err != nil {
		return nil, err
	}

	// Update the order_status to 'completed' in sales_order
	_, err = tx.Exec("UPDATE sales_order SET order_status = 'completed' WHERE id = $1 AND delivery_partner_id = $2 AND order_status != 'completed'", order_id, deliveryPartnerIDFromDB)
	if err != nil {
		return nil, err
	}

	// Check for an existing delivery_order record
	var existingDeliveryOrderID int
	err = tx.QueryRow("SELECT id FROM delivery_order WHERE sales_order_id = $1 AND delivery_partner_id = $2", order_id, deliveryPartnerIDFromDB).Scan(&existingDeliveryOrderID)

	// Update or insert delivery_order record
	if err == sql.ErrNoRows {
		// Insert a new delivery_order record with order_delivered_date and image_url
		_, err = tx.Exec(`
            INSERT INTO delivery_order (sales_order_id, delivery_partner_id, order_delivered_date, image_url)
            VALUES ($1, $2, CURRENT_TIMESTAMP, $3);`, order_id, deliveryPartnerIDFromDB, image)
	} else if err == nil {
		// Update the existing record's order_delivered_date and image_url
		_, err = tx.Exec(`
            UPDATE delivery_order 
            SET order_delivered_date = CURRENT_TIMESTAMP, image_url = $2
            WHERE id = $1;`, existingDeliveryOrderID, image)
	}
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	// Return the delivery completion result
	result := &DeliveryCompletionResult{
		SalesOrderID: order_id,
		OrderStatus:  "completed",
		Image:        image,
	}

	return result, nil
}

func (s *PostgresStore) DeliveryPartnerGetOrderDetails(new_req types.DeliveryPartnerOrderDetails) (*types.DPOrderDetails, error) {
	// Step 1: Retrieve the delivery_partner_id using the phone number
	var deliveryPartnerID int
	err := s.db.QueryRow("SELECT id FROM delivery_partner WHERE phone = $1", new_req.DeliveryPartnerPhone).Scan(&deliveryPartnerID)
	if err != nil {
		// Error handling with more detail
		return nil, fmt.Errorf("error retrieving delivery partner ID: %w", err)
	}

	// Step 2: Use the deliveryPartnerID to fetch order details
	query := `
        SELECT so.id, so.delivery_partner_id, so.cart_id, so.payment_type, so.store_id, s.name, so.customer_id, c.phone,
               a.street_address, a.line_one_address, a.line_two_address, a.latitude, a.longitude, sc.subtotal, so.order_date
        FROM sales_order so
        JOIN store s ON so.store_id = s.id
        JOIN customer c ON so.customer_id = c.id
        JOIN address a ON so.address_id = a.id
        JOIN shopping_cart sc ON so.cart_id = sc.id
        WHERE so.id = $1 AND so.delivery_partner_id = $2
    `

	// Variable to hold the order details
	order := &types.DPOrderDetails{}

	// Execute the updated query
	err = s.db.QueryRow(query, new_req.SalesOrderId, deliveryPartnerID).Scan(
		&order.ID, &order.DeliveryPartnerID, &order.CartID, &order.PaymentType, &order.StoreID, &order.StoreName,
		&order.CustomerID, &order.CustomerPhone, &order.DeliveryAddress.StreetAddress,
		&order.DeliveryAddress.LineOneAddress, &order.DeliveryAddress.LineTwoAddress, &order.DeliveryAddress.Latitude,
		&order.DeliveryAddress.Longitude, &order.Subtotal, &order.OrderDate)
	if err != nil {
		// Error handling with more detail
		return nil, fmt.Errorf("error fetching order details: %w", err)
	}

	return order, nil
}

type DeliveryCompletionResult struct {
	SalesOrderID int    `json:"sales_order_id"`
	OrderStatus  string `json:"order_status"`
	Image        string `json:"image"`
}

type DeliveryPartnerDispatchResult struct {
	DeliveryPartnerName string `json:"delivery_partner_name"`
	SalesOrderID        int    `json:"sales_order_id"`
	OrderStatus         string `json:"order_status"`
	Location            int    `json:"location"`
}

type DeliveryPartnerArriveResult struct {
	SalesOrderID int    `json:"sales_order_id"`
	OrderStatus  string `json:"order_status"`
}

type OrderStatusError struct {
	Status string
}

func (e *OrderStatusError) Error() string {
	return fmt.Sprintf("order status: %s", e.Status)
}

type OrderAccepted struct {
	CustomerAddress string  `json:"customer_address"`
	NumberOfItems   int     `json:"number_of_items"` // Assuming you have a way to count this
	StoreAddress    string  `json:"store_address"`
	CustomerPhone   string  `json:"customer_phone"`
	CustomerName    string  `json:"customer_name"`
	PaymentMethod   string  `json:"payment_method"`
	OrderAmount     float64 `json:"order_amount,omitempty"` // Include if payment method is cash
	IsPaid          bool    `json:"is_paid"`
}

func (s *PostgresStore) Update_FCM_Token_Delivery_Partner(phone string, fcm_token string) (*types.Delivery_Partner, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // This will rollback any changes in case of error or if the commit fails

	// Reset existing rows with the same fcm_token to 0
	resetStatement := `
        UPDATE delivery_partner
        SET fcm_token = '0'
        WHERE fcm_token = $1
    `
	_, err = tx.Exec(resetStatement, fcm_token)
	if err != nil {
		return nil, err
	}

	// Update the fcm_token for the matching phone
	sqlStatement := `
        UPDATE delivery_partner
        SET fcm_token = $1
        WHERE phone = $2
        RETURNING id, name, fcm_token, store_id, phone, address, created_at
    `

	// Execute the SQL statement
	row := tx.QueryRow(sqlStatement, fcm_token, phone)

	partner := &types.Delivery_Partner{}
	err = row.Scan(&partner.ID, &partner.Name, &partner.FCM_Token, &partner.Store_ID, &partner.Phone, &partner.Address, &partner.Created_At)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return partner, nil
}

// 2. Create a function to retrieve all delivery partners
func (s *PostgresStore) Get_All_Delivery_Partners() ([]*types.Delivery_Partner, error) {
	query := `SELECT id, name, fcm_token, store_id, phone, address, created_at FROM delivery_partner`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.Delivery_Partner{}
	for rows.Next() {
		partner, err := scan_Into_Delivery_Partner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}
	return partners, nil
}

// 3. Create a function to retrieve a delivery partner by phone
func (s *PostgresStore) Get_Delivery_Partner_By_Phone(phone string) (*types.Delivery_Partner, error) {
	rows, err := s.db.Query("SELECT id, name, fcm_token, store_id, phone, address, created_at, available FROM delivery_partner where phone = $1", phone)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.Delivery_Partner{}
	for rows.Next() {
		partner, err := scan_Into_Delivery_Partner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}

	if len(partners) == 0 {
		return nil, nil
	}
	return partners[0], nil
}

// Assuming you have a scan_Into_Delivery_Partner function to scan row data into the Delivery_Partner type.
func scan_Into_Delivery_Partner(rows *sql.Rows) (*types.Delivery_Partner, error) {
	partner := &types.Delivery_Partner{}
	err := rows.Scan(&partner.ID, &partner.Name, &partner.FCM_Token, &partner.Store_ID, &partner.Phone, &partner.Address, &partner.Created_At, &partner.Available)
	if err != nil {
		return nil, err
	}
	return partner, nil
}

type DeliveryPartner struct {
	Name         string `json:"name"`
	Availability bool   `json:"availability"`
}

func (s *PostgresStore) DeliveryPartnerLogin(phone string) (*DeliveryPartner, error) {
	query := `
	INSERT INTO delivery_partner 
		(name, fcm_token, store_id, phone, address, available, current_location, active_deliveries) 
	VALUES 
		('', '', 1, $1, '', false, '', 0)
	RETURNING name, available;`

	// Assuming you have a connection to the database
	var partner DeliveryPartner
	err := s.db.QueryRow(query, phone).Scan(&partner.Name, &partner.Availability)
	if err != nil {
		return nil, fmt.Errorf("error creating delivery partner: %w", err)
	}

	return &partner, nil
}

func (s *PostgresStore) AssignDeliveryPartnerToSalesOrder(cart_id int, phone string) (bool, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return false, fmt.Errorf("failed to start transaction: %s", err)
	}
	defer tx.Rollback() // Ensure rollback in case of error

	var deliveryPartnerID int
	var salesOrderID int

	// SQL query to fetch the delivery partner's ID based on the phone number
	query := `SELECT id FROM delivery_partner WHERE phone = $1`
	err = tx.QueryRow(query, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return false, fmt.Errorf("error fetching delivery partner by phone: %s", err)
	}

	// Update the delivery_partner_id in sales_order and fetch sales_order_id
	err = tx.QueryRow(`
        UPDATE sales_order 
        SET delivery_partner_id = $1 
        WHERE cart_id = $2
        RETURNING id
    `, deliveryPartnerID, cart_id).Scan(&salesOrderID)
	if err != nil {
		return false, fmt.Errorf("error assigning delivery partner for order of cart %d: %s", cart_id, err)
	}

	// Check for an existing delivery_order record
	var existingDeliveryOrderID int
	err = tx.QueryRow(`
        SELECT id FROM delivery_order 
        WHERE sales_order_id = $1 AND delivery_partner_id = $2
    `, salesOrderID, deliveryPartnerID).Scan(&existingDeliveryOrderID)

	// Update or insert delivery_order record
	if err == sql.ErrNoRows {
		// Insert a new delivery_order record with order_assigned_date as current timestamp
		_, err = tx.Exec(`
            INSERT INTO delivery_order (sales_order_id, delivery_partner_id, order_assigned_date)
            VALUES ($1, $2, CURRENT_TIMESTAMP);`, salesOrderID, deliveryPartnerID)

		if err != nil {
			return false, fmt.Errorf("error inserting delivery_order record: %s", err)
		}

	} else if err != nil {
		return false, fmt.Errorf("error updating delivery_order record: %s", err)
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return false, fmt.Errorf("error committing transaction: %s", err)
	}

	return true, nil
}

func (s *PostgresStore) GetOldestUnassignedOrder() (int, error) {
	var cartID int
	query := `
        SELECT cart_id 
        FROM sales_order
        WHERE delivery_partner_id IS NULL AND order_status != 'completed'
        ORDER BY order_date ASC
        LIMIT 1
    `

	err := s.db.QueryRow(query).Scan(&cartID)
	if err != nil {
		if err == sql.ErrNoRows {
			// No unassigned orders
			return 0, nil
		}
		return 0, err
	}

	return cartID, nil
}

func (s *PostgresStore) SendOtpDeliveryPartnerMSG91(phone string) (*types.SendOTPResponse, error) {
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

func (s *PostgresStore) VerifyOtpDeliveryPartnerMSG91(phone string, otp int, fcm string) (*types.DeliveryPartnerLogin, error) {
	// Construct the URL with query parameters

	if phone == "1234567890" {
		var response types.DeliveryPartnerLogin
		var otpresponse types.VerifyOTPResponse
		otpresponse.Type = "success"
		otpresponse.Message = "test user - OTP verified successfully"
		deliveryPartnerPtr, err := s.GetDeliveryPartnerByPhone(phone, fcm)
		if err != nil {
			return nil, err
		}

		response.DeliveryPartner = *deliveryPartnerPtr // Dereference the pointer
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
		var response types.DeliveryPartnerLogin
		deliveryPartnerPtr, err := s.GetDeliveryPartnerByPhone(phone, fcm)
		if err != nil {
			return nil, err
		}

		response.DeliveryPartner = *deliveryPartnerPtr // Dereference the pointer
		response.Message = otpresponse.Message
		response.Type = otpresponse.Type
		return &response, nil
	} else {
		// OTP verification failed
		return nil, fmt.Errorf("OTP verification failed")
	}
}

func (s *PostgresStore) GetDeliveryPartnerByPhone(phone string, fcm string) (*types.DeliveryPartnerData, error) {
	fmt.Println("Started GetDeliveryPartnerByPhone")

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // Ensure rollback in case of failure

	// Clear FCM for any customer that might have it
	clearFCMSQL := `UPDATE delivery_partner SET fcm = NULL WHERE fcm = $1`
	if _, err := tx.Exec(clearFCMSQL, fcm); err != nil {
		return nil, err
	}

	// Update FCM for the customer with the given phone and fetch necessary fields
	updateFCMSQL := `
        UPDATE delivery_partner 
        SET fcm = $1 
        WHERE phone = $2 
        RETURNING id, name, phone, address,  created_at, token`
	row := tx.QueryRow(updateFCMSQL, fcm, phone)

	var deliveryPartner types.DeliveryPartnerData
	var token sql.NullString

	err = row.Scan(
		&deliveryPartner.ID,
		&deliveryPartner.Name,
		&deliveryPartner.Phone,
		&deliveryPartner.Address,
		&deliveryPartner.Created_At,
		&token,
	)

	if err == sql.ErrNoRows {
		newToken, _ := uuid.NewUUID() // Generate a new UUID for the token
		insertSQL := `
            INSERT INTO delivery_partner (name, phone, address, token, fcm, store_id)
            VALUES ('', $1, '', $2, $3, $4)
            RETURNING id, name, phone, address, created_at, token`
		row = tx.QueryRow(insertSQL, phone, newToken, fcm, 1)

		// Scan the new customer data
		err = row.Scan(
			&deliveryPartner.ID,
			&deliveryPartner.Name,
			&deliveryPartner.Phone,
			&deliveryPartner.Address,
			&deliveryPartner.Created_At,
			&token,
		)
		if err != nil {
			return nil, err
		}
		deliveryPartner.Token = newToken
	} else if err != nil {
		return nil, err
	}

	// Check if token needs to be generated
	if !token.Valid || token.String == "" {
		newToken, _ := uuid.NewUUID() // Generate a new UUID for the token
		updateTokenSQL := `UPDATE delivery_partner SET token = $1 WHERE id = $2`
		if _, err := tx.Exec(updateTokenSQL, newToken, deliveryPartner.ID); err != nil {
			return nil, err
		}
		deliveryPartner.Token = newToken // Set the newly generated token in the customer object
	} else {
		deliveryPartner.Token = uuid.MustParse(token.String) // Use the existing token if valid
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	fmt.Println("Transaction Successful")
	return &deliveryPartner, nil
}
