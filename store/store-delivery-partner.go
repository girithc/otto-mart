package store

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/girithc/pronto-go/types"
	"github.com/google/uuid"

	"github.com/lib/pq"
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

type OrderAssigned struct {
	ID                int       `json:"id"`
	DeliveryPartnerID int       `json:"delivery_partner_id,omitempty"` // omit if zero
	StoreID           int       `json:"store_id"`
	OrderDate         time.Time `json:"order_date"`
	OrderStatus       string    `json:"order_status"`
}

func (s *PostgresStore) GetFirstAssignedOrder(phone string) (*OrderAssigned, error) {
	// Define the query to get the oldest order without a delivery partner assigned
	query := `
        SELECT id, store_id, order_date, order_status
        FROM sales_order
        WHERE delivery_partner_id IS NULL AND order_status NOT IN ('completed')
        ORDER BY order_date ASC
        LIMIT 1
    `

	// Variable to hold the order details
	order := &OrderAssigned{}

	// Execute the query
	err := s.db.QueryRow(query).Scan(&order.ID, &order.StoreID, &order.OrderDate, &order.OrderStatus)
	if err != nil {
		if err == sql.ErrNoRows {
			// No unassigned order found, return an OrderAssigned object with default values
			return &OrderAssigned{
				ID:          0,
				StoreID:     0,
				OrderDate:   time.Time{},
				OrderStatus: "no order",
			}, nil
		}
		return nil, fmt.Errorf("error querying for unassigned order: %s", err)
	}
	return order, nil
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

func (s *PostgresStore) DeliveryPartnerAcceptOrder(phone string, order_id int) ([]OrderAssignResponse, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	var deliveryPartnerID int
	err = tx.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	var existingDeliveryPartnerID sql.NullInt64
	err = tx.QueryRow(`SELECT delivery_partner_id FROM sales_order WHERE id = $1;`, order_id).Scan(&existingDeliveryPartnerID)
	if err != nil {
		return nil, err
	}
	if existingDeliveryPartnerID.Valid && existingDeliveryPartnerID.Int64 != int64(deliveryPartnerID) {
		return nil, fmt.Errorf("order is already assigned to another delivery partner")
	}

	_, err = tx.Exec(`UPDATE sales_order SET delivery_partner_id = $1, order_dp_status = 'accepted' WHERE id = $2;`, deliveryPartnerID, order_id)
	if err != nil {
		return nil, err
	}

	if err = tx.Commit(); err != nil {
		return nil, err
	}

	return s.GetAssignedOrder(deliveryPartnerID, phone)
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
	OrderOTP       string    `json:"order_otp"`
	NumberOfItems  int       `json:"number_of_items"`
}

func (s *PostgresStore) DeliveryPartnerPickupOrder(phone string, order_id int) (*PickupOrderInfo, error) {
	var info PickupOrderInfo

	// Get delivery partner ID from phone number
	var deliveryPartnerID int
	err := s.db.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	var cartID int
	orderQuery := `
    SELECT c.name, c.phone, so.order_date, so.order_status, COALESCE(sc.address_id, so.address_id) AS address_id, so.cart_id
    FROM sales_order so
    LEFT JOIN shopping_cart sc ON so.cart_id = sc.id
    INNER JOIN customer c ON so.customer_id = c.id
    WHERE so.id = $1 AND so.delivery_partner_id = $2 AND so.order_dp_status = 'accepted' AND so.order_status != 'completed';`

	err = s.db.QueryRow(orderQuery, order_id, deliveryPartnerID).Scan(&info.CustomerName, &info.CustomerPhone, &info.OrderDate, &info.OrderStatus, &cartID, &info.NumberOfItems)
	if err != nil {
		return nil, err
	}

	// Query to get address information using the obtained addressID
	addressQuery := `SELECT latitude, longitude, line_one_address, line_two_address, street_address FROM address WHERE id = $1;`
	err = s.db.QueryRow(addressQuery, cartID).Scan(&info.Latitude, &info.Longitude, &info.LineOneAddress, &info.LineTwoAddress, &info.StreetAddress)
	if err != nil {
		return nil, err
	}

	// Query to get OTP
	otpQuery := `SELECT otp_code FROM sales_order_otp WHERE cart_id = $1 AND active = true LIMIT 1;`
	err = s.db.QueryRow(otpQuery, cartID).Scan(&info.OrderOTP)
	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to fetch OTP for order %d: %s", order_id, err)
	}

	// Query to calculate total number of items
	itemsQuery := `SELECT SUM(quantity) FROM cart_item WHERE cart_id = $1;`
	err = s.db.QueryRow(itemsQuery, cartID).Scan(&info.NumberOfItems)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate total number of items for cart %d: %s", cartID, err)
	}

	return &info, nil
}

type DeliveryOrderDetails struct {
	CustomerName   string        `json:"customer_name"`
	CustomerPhone  string        `json:"customer_phone"`
	Latitude       float64       `json:"latitude"`
	Longitude      float64       `json:"longitude"`
	LineOneAddress string        `json:"line_one_address"`
	LineTwoAddress string        `json:"line_two_address"`
	StreetAddress  string        `json:"street_address"`
	OrderDate      time.Time     `json:"order_date"`
	OrderStatus    string        `json:"order_status"`
	OrderOTP       string        `json:"order_otp"`
	Items          []OrderDetail `json:"items"`
}

func (s *PostgresStore) DeliveryPartnerGoDeliverOrder(phone string, orderId int) (*DeliveryOrderDetails, error) {
    tx, err := s.db.Begin()
    if err != nil {
        log.Printf("Error beginning transaction: %v", err)
        return nil, fmt.Errorf("Error beginning transaction: %v", err)
    }
    defer tx.Rollback()

    // Fetch delivery partner ID
    var deliveryPartnerID int
    err = tx.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
    if err != nil {
        log.Printf("Error fetching delivery partner ID: %v", err)
        return nil, fmt.Errorf("Error fetching delivery partner ID: %v", err)
    }

    // Update the order status to 'dispatched' if it's 'accepted' or 'packed'
    result, err := tx.Exec(`
        UPDATE sales_order
        SET order_status = 'dispatched'
        WHERE id = $1 AND delivery_partner_id = $2 AND order_status IN ('accepted', 'packed');
    `, orderId, deliveryPartnerID)
    if err != nil {
        log.Printf("Error updating order status: %v", err)
        return nil, fmt.Errorf("Error updating order status: %v", err)
    }
    rowsAffected, err := result.RowsAffected()
    if err != nil {
        log.Printf("Error getting rows affected: %v", err)
        return nil, fmt.Errorf("Error getting rows affected: %v", err)
    }
    log.Printf("Rows affected by update: %d", rowsAffected)

    var details DeliveryOrderDetails

    // Fetch order and customer details
    err = tx.QueryRow(`
        SELECT c.name, c.phone, a.latitude, a.longitude, a.line_one_address, a.line_two_address, a.street_address,
               so.order_date, so.order_status, so_otp.otp_code
        FROM sales_order so
        JOIN customer c ON so.customer_id = c.id
        JOIN address a ON so.address_id = a.id
        LEFT JOIN sales_order_otp so_otp ON so.cart_id = so_otp.cart_id AND so_otp.active = true
        WHERE so.id = $1;
    `, orderId).Scan(
        &details.CustomerName, &details.CustomerPhone, &details.Latitude, &details.Longitude,
        &details.LineOneAddress, &details.LineTwoAddress, &details.StreetAddress, &details.OrderDate,
        &details.OrderStatus, &details.OrderOTP,
    )
    if err != nil {
        log.Printf("Error fetching order and customer details: %v", err)
        return nil, fmt.Errorf("Error fetching order and customer details: %v", err)
    }

    // Fetch items details for the order
    items, err := s.GetOrderDetails(orderId)
    if err != nil {
        log.Printf("Error fetching order details: %v", err)
        return nil, fmt.Errorf("Error fetching order details: %v", err)
    }
    if len(items) == 0 {
        log.Printf("No items found for order ID: %d", orderId)
        return nil, fmt.Errorf("No items found for order ID: %d", orderId)
    }

    details.Items = items

    // Commit the transaction
    if err := tx.Commit(); err != nil {
        log.Printf("Error committing transaction: %v", err)
        return nil, fmt.Errorf("Error committing transaction: %v", err)
    }

    // Return the complete order details including items
    return &details, nil
}



type ArriveOrderDetails struct {
	CustomerName   string        `json:"customer_name"`
	CustomerPhone  string        `json:"customer_phone"`
	Latitude       float64       `json:"latitude"`
	Longitude      float64       `json:"longitude"`
	LineOneAddress string        `json:"line_one_address"`
	LineTwoAddress string        `json:"line_two_address"`
	StreetAddress  string        `json:"street_address"`
	OrderDate      time.Time     `json:"order_date"`
	OrderStatus    string        `json:"order_status"`
	OrderOTP       string        `json:"order_otp"`
	Items          []OrderDetail `json:"items"`
	Subtotal       int           `json:"subtotal"`
	Paid           bool          `json:"paid"`
	PaymentType    string        `json:"payment_type"`
}

func (s *PostgresStore) DeliveryPartnerArriveDestination(phone string, orderId int) (*ArriveOrderDetails, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Fetch delivery partner ID
	var deliveryPartnerID int
	err = tx.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	// Update the order status to 'arrived'
	_, err = tx.Exec(`UPDATE sales_order SET order_status = 'arrived' WHERE id = $1;`, orderId)
	if err != nil {
		return nil, err
	}

	var details ArriveOrderDetails

	// Fetch order, customer, address details, and shopping cart subtotal
	err = tx.QueryRow(`
        SELECT c.name, c.phone, a.latitude, a.longitude, a.line_one_address, a.line_two_address, a.street_address,
               so.order_date, so.order_status, so_otp.otp_code, sc.subtotal, so.paid, so.payment_type
        FROM sales_order so
        JOIN customer c ON so.customer_id = c.id
        JOIN address a ON so.address_id = a.id
        JOIN shopping_cart sc ON so.cart_id = sc.id
        LEFT JOIN sales_order_otp so_otp ON so.cart_id = so_otp.cart_id AND so_otp.active = true
        WHERE so.id = $1;
    `, orderId).Scan(
		&details.CustomerName, &details.CustomerPhone, &details.Latitude, &details.Longitude,
		&details.LineOneAddress, &details.LineTwoAddress, &details.StreetAddress, &details.OrderDate,
		&details.OrderStatus, &details.OrderOTP, &details.Subtotal, &details.Paid, &details.PaymentType,
	)
	if err != nil {
		return nil, err
	}

	// Fetch items details for the order
	details.Items, err = s.GetOrderDetails(orderId)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &details, nil
}

type OrderDetailsInfo struct {
	CustomerName    string        `json:"customer_name"`
	CustomerPhone   string        `json:"customer_phone"`
	Latitude        float64       `json:"latitude"`
	Longitude       float64       `json:"longitude"`
	LineOneAddress  string        `json:"line_one_address"`
	LineTwoAddress  string        `json:"line_two_address"`
	StreetAddress   string        `json:"street_address"`
	OrderDate       time.Time     `json:"order_date"`
	OrderStatus     string        `json:"order_status"`
	OrderOTP        string        `json:"order_otp"`
	Items           []OrderDetail `json:"items"`
	Subtotal        int           `json:"subtotal"`
	Paid            bool          `json:"paid"`
	PaymentType     string        `json:"payment_type"`
	AmountCollected int           `json:"amount_collected"`
}

func (s *PostgresStore) DeliveryPartnerGetOrderDetails(phone string, orderId int) (*OrderDetailsInfo, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Fetch delivery partner ID
	var deliveryPartnerID int
	err = tx.QueryRow(`SELECT id FROM delivery_partner WHERE phone = $1;`, phone).Scan(&deliveryPartnerID)
	if err != nil {
		return nil, err
	}

	var details OrderDetailsInfo

	// Fetch order, customer, address details, and shopping cart subtotal
	err = tx.QueryRow(`
        SELECT c.name, c.phone, a.latitude, a.longitude, a.line_one_address, a.line_two_address, a.street_address,
               so.order_date, so.order_status, so_otp.otp_code, sc.subtotal, so.paid, so.payment_type
        FROM sales_order so
        JOIN customer c ON so.customer_id = c.id
        JOIN address a ON so.address_id = a.id
        JOIN shopping_cart sc ON so.cart_id = sc.id
        LEFT JOIN sales_order_otp so_otp ON so.cart_id = so_otp.cart_id AND so_otp.active = true
        WHERE so.id = $1;
    `, orderId).Scan(
		&details.CustomerName, &details.CustomerPhone, &details.Latitude, &details.Longitude,
		&details.LineOneAddress, &details.LineTwoAddress, &details.StreetAddress, &details.OrderDate,
		&details.OrderStatus, &details.OrderOTP, &details.Subtotal, &details.Paid, &details.PaymentType,
	)
	if err != nil {
		return nil, err
	}

	// Fetch items details for the order
	details.Items, err = s.GetOrderDetails(orderId)
	if err != nil {
		return nil, err
	}

	// Fetch the amount collected from the delivery_order table
	err = tx.QueryRow(`
        SELECT amount_collected
        FROM delivery_order
        WHERE sales_order_id = $1 AND delivery_partner_id = $2;
    `, orderId, deliveryPartnerID).Scan(&details.AmountCollected)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &details, nil
}

type OrderAssignResponse struct {
	OrderId     int       `json:"order_id"`
	OrderStatus string    `json:"order_status"`
	OrderDate   time.Time `json:"order_date"`
	OrderOTP    string    `json:"order_otp"`
}

func (s *PostgresStore) GetAssignedOrder(storeId int, phone string) ([]OrderAssignResponse, error) {
	var responses []OrderAssignResponse

	// Query to fetch orders assigned to the given store and delivery partner.
	ordersQuery := `
	SELECT so.id, so.cart_id, so.order_status, so.order_date
	FROM sales_order so
	JOIN delivery_partner dp ON so.delivery_partner_id = dp.id
	WHERE so.store_id = $1 AND dp.phone = $2
	ORDER BY so.order_date DESC;`

	// Execute the query.
	rows, err := s.db.Query(ordersQuery, storeId, phone)
	if err != nil {
		return nil, fmt.Errorf("error querying orders: %s", err)
	}
	defer rows.Close()

	// Iterate through the result set.
	for rows.Next() {
		var response OrderAssignResponse
		var cartId int
		var orderDateStr string

		if err := rows.Scan(&response.OrderId, &cartId, &response.OrderStatus, &orderDateStr); err != nil {
			return nil, fmt.Errorf("error scanning orders: %s", err)
		}

		// Convert the order_date string to time.Time using the correct layout
		const layout = "2006-01-02 15:04:05.999999 -0700 MST"
		response.OrderDate, err = time.Parse(layout, orderDateStr)
		if err != nil {
			return nil, fmt.Errorf("error parsing order date: %s", err)
		}

		// Fetch or generate OTP for each order.
		otp, err := s.fetchOrGenerateOtp(cartId, storeId)
		if err != nil {
			return nil, fmt.Errorf("error handling OTP for cart_id %d: %s", cartId, err)
		}
		response.OrderOTP = otp

		// Append the response.
		responses = append(responses, response)
	}

	// Check for any error encountered during iteration.
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over orders: %s", err)
	}

	return responses, nil
}


// fetchOrGenerateOtp checks if an OTP exists for a given cartId, generates a new one if not.
func (s *PostgresStore) fetchOrGenerateOtp(cartId, storeId int) (string, error) {
	var otp string

	// Check if an OTP already exists.
	checkOtpQuery := `SELECT otp_code FROM sales_order_otp WHERE cart_id = $1`
	err := s.db.QueryRow(checkOtpQuery, cartId).Scan(&otp)
	if err == sql.ErrNoRows { // No OTP found, generate a new one.
		otp, err = generateOtp()
		if err != nil {
			return "", fmt.Errorf("error generating OTP: %s", err)
		}

		// Insert the new OTP.
		insertOtpQuery := `
		INSERT INTO sales_order_otp (store_id, customer_id, cart_id, otp_code, active)
		VALUES ($1, (SELECT customer_id FROM sales_order WHERE cart_id = $2), $2, $3, true)
		ON CONFLICT (cart_id) DO NOTHING;`
		_, err = s.db.Exec(insertOtpQuery, storeId, cartId, otp)
		if err != nil {
			return "", fmt.Errorf("error inserting new OTP: %s", err)
		}
	} else if err != nil { // Handle other errors.
		return "", fmt.Errorf("error checking for existing OTP: %s", err)
	}

	// Return the existing or new OTP.
	return otp, nil
}

func (s *PostgresStore) DeliveryPartnerDispatchOrder(phone string, order_id int) (*DeliveryPartnerDispatchResult, error) {
	var location int

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback() // Ensure transaction is rolled back in case of error

	// Verify the sales order's current status is 'packed'
	var currentStatus string
	err = tx.QueryRow("SELECT order_status FROM sales_order WHERE id = $1", order_id).Scan(&currentStatus)
	if err != nil {
		return nil, fmt.Errorf("failed to verify order status for order ID %d: %w", order_id, err)
	}
	if currentStatus != "packed" {
		return nil, fmt.Errorf("order %d is not in packed status", order_id)
	}

	// Verify the delivery partner ID and retrieve delivery partner name
	var deliveryPartnerName string
	var deliveryPartnerIDFromDB int
	err = tx.QueryRow("SELECT id, name FROM delivery_partner WHERE phone = $1", phone).Scan(&deliveryPartnerIDFromDB, &deliveryPartnerName)
	if err != nil {
		return nil, fmt.Errorf("failed to verify delivery partner for phone %s: %w", phone, err)
	}

	// Retrieve the location of the delivery shelf associated with the sales order
	var deliveryShelfID int
	err = tx.QueryRow("SELECT delivery_shelf_id FROM packer_shelf WHERE sales_order_id = $1", order_id).Scan(&deliveryShelfID)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve delivery shelf ID for order ID %d: %w", order_id, err)
	}

	err = tx.QueryRow("SELECT location FROM delivery_shelf WHERE id = $1", deliveryShelfID).Scan(&location)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve location for delivery shelf ID %d: %w", deliveryShelfID, err)
	}

	// Update the order_status to 'dispatched' in sales_order
	_, err = tx.Exec("UPDATE sales_order SET order_status = 'dispatched' WHERE id = $1 AND delivery_partner_id = $2 AND order_status != 'completed'", order_id, deliveryPartnerIDFromDB)
	if err != nil {
		return nil, fmt.Errorf("failed to update order status to 'dispatched' for order ID %d: %w", order_id, err)
	}

	// Update the pickup_time and set active to false in packer_shelf for the associated sales_order_id
	_, err = tx.Exec("UPDATE packer_shelf SET pickup_time = CURRENT_TIMESTAMP, active = false WHERE sales_order_id = $1", order_id)
	if err != nil {
		return nil, fmt.Errorf("failed to update packer_shelf for order ID %d: %w", order_id, err)
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	// Return the dispatch result
	result := &DeliveryPartnerDispatchResult{
		DeliveryPartnerName: deliveryPartnerName,
		SalesOrderID:        order_id,
		OrderStatus:         "dispatched",
		Location:            location, // Now includes the location from the delivery shelf
	}

	return result, nil
}

func (s *PostgresStore) PackerDispatchOrderHistory(storeId int) ([]DispatchOrderHistory, error) {
	query := `
    SELECT ps.pickup_time, ps.drop_time, ds.location, p.name as packer_name, p.phone as packer_phone, dp.name as delivery_partner_name, dp.phone as delivery_partner_phone
    FROM Packer_Shelf ps
    INNER JOIN Packer p ON ps.packer_id = p.id
    INNER JOIN Delivery_Shelf ds ON ps.delivery_shelf_id = ds.id
    INNER JOIN Sales_Order so ON ps.sales_order_id = so.id
    INNER JOIN Delivery_Partner dp ON so.delivery_partner_id = dp.id
    WHERE ds.store_id = $1
    ORDER BY ps.pickup_time DESC
    `

	rows, err := s.db.Query(query, storeId)
	if err != nil {
		return nil, fmt.Errorf("error querying dispatch order history: %w", err)
	}
	defer rows.Close()

	var histories []DispatchOrderHistory
	for rows.Next() {
		var history DispatchOrderHistory
		err := rows.Scan(&history.PickupTime, &history.DropTime, &history.Location, &history.PackerName, &history.PackerPhone, &history.DeliveryPartnerName, &history.DeliveryPartnerPhone)
		if err != nil {
			return nil, fmt.Errorf("error scanning dispatch order history: %w", err)
		}
		histories = append(histories, history)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating through dispatch order history results: %w", err)
	}

	return histories, nil
}

type DispatchOrderHistory struct {
	PickupTime           pq.NullTime // Using pq.NullTime for time fields that can be null
	DropTime             pq.NullTime
	Location             sql.NullInt64 // Using sql.NullInt64 for an integer field that can be null
	PackerName           sql.NullString
	PackerPhone          sql.NullString
	DeliveryPartnerName  sql.NullString
	DeliveryPartnerPhone sql.NullString
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

type DeliveryCompletionResult struct {
	Success bool `json:"success"`
}

func (s *PostgresStore) DeliveryPartnerCompleteOrderDelivery(phone string, order_id int, amountCollected int) (*DeliveryCompletionResult, error) {
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
	_, err = tx.Exec(`
        UPDATE sales_order
        SET order_status = 'completed'
        WHERE id = $1 AND delivery_partner_id = $2 AND order_status != 'completed';
    `, order_id, deliveryPartnerIDFromDB)
	if err != nil {
		return nil, err
	}

	// Check if a delivery_order record already exists
	var exists bool
	err = tx.QueryRow(`
        SELECT EXISTS(
            SELECT 1 FROM delivery_order 
            WHERE sales_order_id = $1 AND delivery_partner_id = $2
        );
    `, order_id, deliveryPartnerIDFromDB).Scan(&exists)
	if err != nil {
		return nil, err
	}

	if exists {
		// Update the existing delivery_order record
		_, err = tx.Exec(`
            UPDATE delivery_order
            SET order_delivered_date = CURRENT_TIMESTAMP, amount_collected = $3
            WHERE sales_order_id = $1 AND delivery_partner_id = $2;
        `, order_id, deliveryPartnerIDFromDB, amountCollected)
		if err != nil {
			return nil, err
		}
	} else {
		// Insert a new delivery_order record
		_, err = tx.Exec(`
            INSERT INTO delivery_order (sales_order_id, delivery_partner_id, order_delivered_date, amount_collected)
            VALUES ($1, $2, CURRENT_TIMESTAMP, $3);
        `, order_id, deliveryPartnerIDFromDB, amountCollected)
		if err != nil {
			return nil, err
		}
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	if amountCollected > 0 {

		// Verify the delivery partner ID
		var cartId int
		err = tx.QueryRow("SELECT cart_id FROM sales_order WHERE id = $1", order_id).Scan(&cartId)
		if err != nil {
			return nil, err
		}
		updateQuery := `
		UPDATE transaction
		SET status = $1, 
			response_code = $2,
			payment_method = $3
		WHERE cart_id = $4`

		_, _ = s.db.Exec(updateQuery, "COMPLETED", "SUCCESS", "Cash", cartId)
	}

	// Return the delivery completion result indicating success
	return &DeliveryCompletionResult{Success: true}, nil
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
	// Mock response for testing
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
		return nil, fmt.Errorf("OTP verification failed: %s", otpresponse.Message)
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
        RETURNING id, name, phone, address, created_at, token`
	row := tx.QueryRow(updateFCMSQL, fcm, phone)

	var deliveryPartner types.DeliveryPartnerData
	var createdAtStr string
	var token sql.NullString

	err = row.Scan(
		&deliveryPartner.ID,
		&deliveryPartner.Name,
		&deliveryPartner.Phone,
		&deliveryPartner.Address,
		&createdAtStr,
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
			&createdAtStr,
			&token,
		)
		if err != nil {
			return nil, err
		}
		deliveryPartner.Token = newToken
	} else if err != nil {
		return nil, err
	}

	// Convert the created_at string to time.Time using the correct layout
	const layout = "2006-01-02 15:04:05.999999 -0700 MST"
	deliveryPartner.Created_At, err = time.Parse(layout, createdAtStr)
	if err != nil {
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

