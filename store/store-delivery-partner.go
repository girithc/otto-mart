package store

import (
	"database/sql"
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
	// Define the query to retrieve the first assigned order for the specified delivery partner phone number
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

func (s *PostgresStore) DeliveryPartnerAcceptOrder(phone string, order_id int) (*OrderAccepted, error) {
	// Update the order status to reflect acceptance by the delivery partner
	acceptOrderQuery := `
    UPDATE sales_order
    SET order_dp_status = 'accepted'
    WHERE id = $1 AND delivery_partner_id = (
        SELECT id FROM delivery_partner WHERE phone = $2
    ) RETURNING customer_id, store_id, payment_type, paid, cart_id;`

	var customerID, storeID, cartID int
	var paymentMethod string
	var isPaid bool
	err := s.db.QueryRow(acceptOrderQuery, order_id, phone).Scan(&customerID, &storeID, &paymentMethod, &isPaid, &cartID)
	if err != nil {
		return nil, err
	}

	// Fetch customer details
	customerQuery := `SELECT name, phone, address FROM customer WHERE id = $1;`
	orderAccepted := &OrderAccepted{}
	err = s.db.QueryRow(customerQuery, customerID).Scan(&orderAccepted.CustomerName, &orderAccepted.CustomerPhone, &orderAccepted.CustomerAddress)
	if err != nil {
		return nil, err
	}

	// Fetch store address
	storeQuery := `SELECT address FROM store WHERE id = $1;`
	err = s.db.QueryRow(storeQuery, storeID).Scan(&orderAccepted.StoreAddress)
	if err != nil {
		return nil, err
	}

	// Fetch the total quantity of items in the order
	quantityQuery := `SELECT SUM(quantity) FROM cart_item WHERE cart_id = $1;`
	var totalQuantity int
	err = s.db.QueryRow(quantityQuery, cartID).Scan(&totalQuantity)
	if err != nil {
		return nil, err
	}
	orderAccepted.NumberOfItems = totalQuantity

	// Fetch subtotal from shopping_cart if payment method is cash
	if paymentMethod == "cash" {
		subtotalQuery := `SELECT subtotal FROM shopping_cart WHERE id = $1;`
		err = s.db.QueryRow(subtotalQuery, cartID).Scan(&orderAccepted.OrderAmount)
		if err != nil {
			return nil, err
		}
	} else {
		orderAccepted.OrderAmount = 0
	}

	// Set payment method and payment status
	orderAccepted.PaymentMethod = paymentMethod
	orderAccepted.IsPaid = isPaid

	// Add logic to get the number of items in the order
	// Assuming you have a way to get this, for example, a query or a function

	return orderAccepted, nil
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
	rows, err := s.db.Query("SELECT id, name, fcm_token, store_id, phone, address, created_at FROM delivery_partner where phone = $1", phone)
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
func (s *PostgresStore) getNextDeliveryPartner() (int, error) {
	var deliveryPartnerID int
	err := s.db.QueryRow(`
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
	err := rows.Scan(&partner.ID, &partner.Name, &partner.FCM_Token, &partner.Store_ID, &partner.Phone, &partner.Address, &partner.Created_At)
	if err != nil {
		return nil, err
	}
	return partner, nil
}
