package store

import (
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateDeliveryPartnerTable(tx *sql.Tx) error {
	query := `
	create table if not exists delivery_partner(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		fcm_token TEXT NOT NULL,  
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		phone VARCHAR(10) NOT NULL, 
		address TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		available BOOLEAN DEFAULT true,
		current_location TEXT, 
		active_deliveries INT DEFAULT 0,
		last_assigned_time TIMESTAMP DEFAULT NULL
	)`

	_, err := tx.Exec(query)
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
        WHERE dp.phone = $1
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
				assigned, assignErr := s.AssignDeliveryPartnerToSalesOrder(cartID)
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
}

func (s *PostgresStore) DeliveryPartnerAcceptOrder(phone string, order_id int) (*OrderAccepted_DP, error) {
	// Get delivery partner ID from phone number
	dpIDQuery := `SELECT id FROM delivery_partner WHERE phone = $1;`
	var deliveryPartnerID int
	err := s.db.QueryRow(dpIDQuery, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	// Verify that the delivery partner assigned is the one making the request
	checkOrderQuery := `SELECT delivery_partner_id FROM sales_order WHERE id = $1;`
	var existingDeliveryPartnerID sql.NullInt64 // Using sql.NullInt64 to handle null values
	err = s.db.QueryRow(checkOrderQuery, order_id).Scan(&existingDeliveryPartnerID)
	if err != nil {
		return nil, err
	}
	if !existingDeliveryPartnerID.Valid || existingDeliveryPartnerID.Int64 != int64(deliveryPartnerID) {
		return nil, fmt.Errorf("order is not assigned to this delivery partner")
	}

	// Proceed with updating the order as the delivery partner matches
	assignOrderQuery := `
        UPDATE sales_order
        SET order_dp_status = 'accepted'
        WHERE id = $1
        RETURNING store_id, order_date, order_status, order_dp_status;`

	var storeID int
	var orderDate time.Time
	var orderStatus, orderDPStatus string
	err = s.db.QueryRow(assignOrderQuery, order_id).Scan(&storeID, &orderDate, &orderStatus, &orderDPStatus)
	if err != nil {
		return nil, err
	}

	// Fetch store details
	storeQuery := `SELECT name, address FROM store WHERE id = $1;`
	var storeName, storeAddress string
	err = s.db.QueryRow(storeQuery, storeID).Scan(&storeName, &storeAddress)
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
	}

	return acceptedOrder, nil
}

type PickupOrderInfo struct {
	CustomerName   string    `json:"customer_name"`
	CustomerPhone  string    `json:"customer_phone"`
	Latitude       float64   `json:"latitude"`
	Longitude      float64   `json:"longitude"`
	LineOneAddress string    `json:"line_one_address"`
	LineTwoAddress string    `json:"line_two_address"`
	StreetAddress  string    `json:"street_address"`
	OrderDate      time.Time `json:"order_date"`
	OrderStatus    string    `json:"order_status"`
}

func (s *PostgresStore) DeliveryPartnerPickupOrder(phone string, order_id int) (*PickupOrderInfo, error) {
	var info PickupOrderInfo

	// Get delivery partner ID from phone number
	var deliveryPartnerID int
	err := s.db.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	// Updated query to include latitude, longitude, line one and line two address
	query := `
    SELECT c.name, c.phone, a.latitude, a.longitude, a.line_one_address, a.line_two_address, a.street_address, so.order_date, so.order_status
    FROM sales_order so
    INNER JOIN shopping_cart sc ON so.cart_id = sc.id
    INNER JOIN address a ON sc.address_id = a.id
    INNER JOIN customer c ON so.customer_id = c.id
    WHERE so.id = $1 AND so.delivery_partner_id = $2 AND so.order_dp_status = 'accepted';`

	err = s.db.QueryRow(query, order_id, deliveryPartnerID).Scan(&info.CustomerName, &info.CustomerPhone, &info.Latitude, &info.Longitude, &info.LineOneAddress, &info.LineTwoAddress, &info.StreetAddress, &info.OrderDate, &info.OrderStatus)
	if err != nil {
		return nil, err
	}

	// Evaluate order status
	switch info.OrderStatus {
	case "dispatched":
		// Return the information for dispatched orders
		println("Order Not Dispatched")
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
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Verify the sales order's current status is 'packed' and fetch cart_id and packer_id
	var currentStatus string
	err = tx.QueryRow("SELECT order_status FROM sales_order WHERE id = $1", order_id).Scan(&currentStatus)
	if err != nil {
		return nil, err
	}
	if currentStatus != "packed" {
		return nil, errors.New("order is not in packed status")
	}

	// Verify the delivery partner ID and retrieve delivery partner name
	var deliveryPartnerName string
	var deliveryPartnerIDFromDB int
	err = tx.QueryRow("SELECT id, name FROM Delivery_Partner WHERE phone = $1", phone).Scan(&deliveryPartnerIDFromDB, &deliveryPartnerName)
	if err != nil {
		return nil, err
	}

	// Update the order_status to 'dispatched'
	_, err = tx.Exec("UPDATE sales_order SET order_status = 'dispatched' WHERE id = $1", order_id)
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
	}

	return result, nil
}

type DeliveryPartnerDispatchResult struct {
	DeliveryPartnerName string `json:"delivery_partner_name"`
	SalesOrderID        int    `json:"sales_order_id"`
	OrderStatus         string `json:"order_status"`
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

// updated
func (s *PostgresStore) getNextDeliveryPartner(tx *sql.Tx) (int, error) {
	var deliveryPartnerID int
	err := tx.QueryRow(`
		SELECT id 
		FROM delivery_partner 
		WHERE available = true 
		ORDER BY last_assigned_time ASC, active_deliveries ASC 
		LIMIT 1
	`).Scan(&deliveryPartnerID)
	if err != nil {
		return 0, err
	}
	return deliveryPartnerID, nil
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

func (s *PostgresStore) AssignDeliveryPartnerToSalesOrder(cart_id int) (bool, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return false, fmt.Errorf("failed to start transaction: %s", err)
	}

	deliveryPartnerID, err := s.getNextDeliveryPartner(tx)
	if err != nil {
		return true, fmt.Errorf("error fetching next available delivery partner: %s", err)
	}

	_, err = tx.Exec(`
		UPDATE sales_order 
		SET delivery_partner_id = $1 
		WHERE cart_id = $2
	`, deliveryPartnerID, cart_id)
	if err != nil {
		return true, fmt.Errorf("error assigning delivery partner for order of cart %d: %s", cart_id, err)
	}

	// Update the delivery partner's last_assigned_time or set their availability to false
	_, err = tx.Exec(`
		UPDATE delivery_partner 
		SET last_assigned_time = NOW()
		WHERE id = $1
	`, deliveryPartnerID)
	if err != nil {
		return true, fmt.Errorf("error updating delivery partner details: %s", err)
	}

	err = tx.Commit()
	if err != nil {
		return false, fmt.Errorf("error committing transaction: %s", err)
	}

	return true, nil
}

func (s *PostgresStore) GetOldestUnassignedOrder() (int, error) {
	var cartID int
	query := `
        SELECT cart_id 
        FROM sales_order
        WHERE delivery_partner_id IS NULL
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
