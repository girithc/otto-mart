package store

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) CreateSalesOrderTable(tx *sql.Tx) error {
	// Define the ENUM type for payment_type
	paymentTypeQuery := `DO $$ BEGIN
        CREATE TYPE payment_method AS ENUM ('cash', 'credit card', 'debit card', 'upi', 'net banking');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err := tx.Exec(paymentTypeQuery)
	if err != nil {
		return err
	}

	// Define the ENUM type for order_status
	orderStatusQuery := `DO $$ BEGIN
        CREATE TYPE order_status AS ENUM ('received', 'accepted', 'packed', 'dispatched', 'arrived', 'completed');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err = tx.Exec(orderStatusQuery)
	if err != nil {
		return err
	}

	// Define the ENUM type for order_status
	orderDeliveryPartnerStatus := `DO $$ BEGIN
        CREATE TYPE dp_status AS ENUM ('accepted', 'denied', 'pending');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err = tx.Exec(orderDeliveryPartnerStatus)
	if err != nil {
		return err
	}

	// Define the ENUM type for order_type
	orderTypeQuery := `DO $$ BEGIN
        CREATE TYPE order_type AS ENUM ('delivery', 'pickup');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err = tx.Exec(orderTypeQuery)
	if err != nil {
		return err
	}

	// Create the sales_order table with order_status field
	query := `create table if not exists sales_order (
        id SERIAL PRIMARY KEY,
        delivery_partner_id INT REFERENCES Delivery_Partner(id) ON DELETE CASCADE,
        packer_id INT REFERENCES Packer(id) ON DELETE CASCADE,
		cart_id INT REFERENCES Shopping_Cart(id) ON DELETE CASCADE NOT NULL,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
		transaction_id INT,
		address_id INT REFERENCES Address(id) ON DELETE CASCADE NOT NULL,
        paid BOOLEAN NOT NULL DEFAULT false,
        payment_type payment_method DEFAULT 'cash',
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        order_status order_status DEFAULT 'received',
		order_dp_status dp_status DEFAULT 'pending',
		order_type order_type DEFAULT 'pickup'
    )`

	_, err = tx.Exec(query)
	if err != nil {
		return err
	}

	// Alter the sales_order table to add the order_type column with a default value of 'pickup'
	alterTableQuery := `ALTER TABLE sales_order
        ADD COLUMN IF NOT EXISTS order_type order_type DEFAULT 'pickup';`

	_, err = tx.Exec(alterTableQuery)
	if err != nil {
		return err
	}

	return err
}

func (s *PostgresStore) CreateSalesOrderOtpTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS sales_order_otp (
        id SERIAL PRIMARY KEY,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
        cart_id INT REFERENCES Shopping_Cart(id) ON DELETE CASCADE NOT NULL,
        otp_code VARCHAR(6) NOT NULL,  -- Changed to VARCHAR(6)
        active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(cart_id)
    );
    `

	_, err := tx.Exec(query)
	if err != nil {
		return err
	}

	return nil
}

func (s *PostgresStore) CreateOrderTimelineTable(tx *sql.Tx) error {
	// Create the combined ENUM type
	combinedStatusQuery := `DO $$ BEGIN
        CREATE TYPE combined_order_status AS ENUM (
            'received', 'accepted', 'packed','transit','dispatched', 'arrived', 'completed',
             'denied', 'pending' 
        );
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err := tx.Exec(combinedStatusQuery)
	if err != nil {
		return fmt.Errorf("error creating combined_order_status ENUM type: %w", err)
	}

	// Create the order_timeline table
	createTimelineTableQuery := `
    CREATE TABLE IF NOT EXISTS order_timeline (
        id SERIAL PRIMARY KEY,
        order_id INT REFERENCES sales_order(id) ON DELETE CASCADE,
        past_status combined_order_status,
        current_status combined_order_status,
        packer_id INT REFERENCES Packer(id) ON DELETE SET NULL,
        delivery_partner_id INT REFERENCES Delivery_Partner(id) ON DELETE SET NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err = tx.Exec(createTimelineTableQuery)
	if err != nil {
		return fmt.Errorf("error creating order_timeline table: %w", err)
	}

	return nil
}

func (s *PostgresStore) SetSalesOrderForeignKey(tx *sql.Tx) error {
	// Add foreign key constraint to the already created table
	query := `
	DO $$
	BEGIN
		IF NOT EXISTS (
			SELECT constraint_name 
			FROM information_schema.table_constraints 
			WHERE table_name = 'sales_order' AND constraint_name = 'sales_order_transaction_id_fkey'
		) THEN
			ALTER TABLE sales_order 
			ADD CONSTRAINT sales_order_transaction_id_fkey 
			FOREIGN KEY (transaction_id) REFERENCES Transaction(id) ON DELETE CASCADE;
		END IF;
	END
	$$;
	`

	_, err := tx.Exec(query)
	return err
}

func (s *PostgresStore) GetRecentSalesOrderByCustomerId(customerID, storeID, cartID int) (*types.Sales_Order_Cart, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	var so types.Sales_Order_Cart

	query := `SELECT id, cart_id, store_id, customer_id, address_id, paid, payment_type, order_date
              FROM sales_order
              WHERE customer_id = $1 AND store_id = $2 AND cart_id = $3
              ORDER BY order_date DESC
              LIMIT 1`
	err = tx.QueryRow(query, customerID, storeID, cartID).Scan(&so.ID, &so.CartID, &so.StoreID, &so.CustomerID, &so.AddressID, &so.Paid, &so.PaymentType, &so.OrderDate)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	shoppingCartQuery := `SELECT id FROM shopping_cart WHERE customer_id = $1 AND active = true`
	err = tx.QueryRow(shoppingCartQuery, customerID).Scan(&so.NewCartID)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	productListQuery := `SELECT ci.id, ci.item_id, ci.quantity, i.name, i.brand_id, i.quantity AS item_quantity, i.unit_of_quantity, i.description FROM cart_item ci JOIN item i ON ci.item_id = i.id WHERE ci.cart_id = $1`
	rows, err := tx.Query(productListQuery, so.CartID)
	if err != nil {
		tx.Rollback()
		return nil, err
	}
	defer rows.Close()

	var products []types.SOProduct
	for rows.Next() {
		var p types.SOProduct
		if err := rows.Scan(&p.ID, &p.ItemID, &p.Quantity, &p.Name, &p.BrandID, &p.ItemQuantity, &p.UnitOfQuantity, &p.Description); err != nil {
			tx.Rollback()
			return nil, err
		}
		products = append(products, p)
	}
	so.Products = products

	storeQuery := `SELECT id, name, address FROM store WHERE id = $1`
	err = tx.QueryRow(storeQuery, so.StoreID).Scan(&so.Store.ID, &so.Store.Name, &so.Store.Address)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	addressQuery := `SELECT id, latitude, longitude, street_address, line_one_address, line_two_address, city, state, zipcode, is_default FROM address WHERE id = $1`
	err = tx.QueryRow(addressQuery, so.AddressID).Scan(&so.Address.ID, &so.Address.Latitude, &so.Address.Longitude, &so.Address.StreetAddress, &so.Address.LineOneAddress, &so.Address.LineTwoAddress, &so.Address.City, &so.Address.State, &so.Address.Zipcode, &so.Address.IsDefault)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	if err = tx.Commit(); err != nil {
		return nil, err
	}

	return &so, nil
}

type CustomerOrderDetails struct {
	OrderStatus          string      `json:"order_status"`
	OrderDeliveryStatus  string      `json:"order_dp_status"`
	PaymentType          string      `json:"payment_type"`
	PaidStatus           bool        `json:"paid_status"`
	OrderDate            string      `json:"order_date"` // Assuming the date is in string format
	TotalAmountPaid      int         `json:"total_amount_paid"`
	Items                []OrderItem `json:"items"`
	Address              string      `json:"address"` // Added to include the street address
	ItemCost             int         `json:"item_cost"`
	DeliveryFee          int         `json:"delivery_fee"`
	PlatformFee          int         `json:"platform_fee"`
	SmallOrderFee        int         `json:"small_order_fee"`
	RainFee              int         `json:"rain_fee"`
	HighTrafficSurcharge int         `json:"high_traffic_surcharge"`
	PackagingFee         int         `json:"packaging_fee"`
	PeakTimeSurcharge    int         `json:"peak_time_surcharge"`
	Subtotal             int         `json:"subtotal"`
}

type OrderItem struct {
	Name           string `json:"name"`
	Image          string `json:"image"` // Assuming there's a way to determine the primary image
	Quantity       int    `json:"quantity"`
	UnitOfQuantity string `json:"unit_of_quantity"`
	Size           int    `json:"size"`
	SoldPrice      int    `json:"sold_price"` // Added to include the sold price for each item
}

func (s *PostgresStore) GetCustomerPlacedOrder(customerId, cartId int) (*CustomerOrderDetails, error) {
	orderDetails := &CustomerOrderDetails{}

	// Updated query to include a LEFT JOIN with the transaction table
	// This allows fetching the transaction_id either directly from the sales_order
	// or through a matching transaction record by cart_id if sales_order.transaction_id is NULL
	orderQuery := `
		SELECT so.order_status, so.order_dp_status, so.payment_type, so.paid, so.order_date,
		COALESCE(so.transaction_id, t.id) AS transaction_id
		FROM sales_order so
		LEFT JOIN transaction t ON t.cart_id = so.cart_id AND so.transaction_id IS NULL
		WHERE so.customer_id = $1 AND so.cart_id = $2
	`
	var transactionId int
	err := s.db.QueryRow(orderQuery, customerId, cartId).Scan(
		&orderDetails.OrderStatus, &orderDetails.OrderDeliveryStatus, &orderDetails.PaymentType,
		&orderDetails.PaidStatus, &orderDetails.OrderDate, &transactionId,
	)
	if err != nil {
		return nil, fmt.Errorf("error getting order details: %w", err)
	}

	// Query to get the total amount paid from the transaction table
	amountQuery := `
        SELECT t.amount
        FROM transaction t
        WHERE t.id = $1
    `
	err = s.db.QueryRow(amountQuery, transactionId).Scan(&orderDetails.TotalAmountPaid)
	if err != nil {
		return nil, fmt.Errorf("error getting transaction amount: %w", err)
	}

	// Query to get item details, including sold price from the cart_item table
	itemsQuery := `
        SELECT i.name, ci.quantity, i.quantity, i.unit_of_quantity, COALESCE((SELECT image_url FROM item_image WHERE item_id = i.id AND order_position = 1 LIMIT 1), '') AS image, ci.sold_price
        FROM cart_item ci
        JOIN item i ON ci.item_id = i.id
        WHERE ci.cart_id = $1
    `
	rows, err := s.db.Query(itemsQuery, cartId)
	if err != nil {
		return nil, fmt.Errorf("error querying for item details: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var item OrderItem
		if err := rows.Scan(&item.Name, &item.Quantity, &item.Size, &item.UnitOfQuantity, &item.Image, &item.SoldPrice); err != nil {
			return nil, fmt.Errorf("error scanning item details: %w", err)
		}
		orderDetails.Items = append(orderDetails.Items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating item details: %w", err)
	}

	// Query to get fees and subtotal from the shopping_cart table
	feesQuery := `
        SELECT item_cost, delivery_fee, platform_fee, small_order_fee, rain_fee, high_traffic_surcharge, packaging_fee, peak_time_surcharge, subtotal
        FROM shopping_cart
        WHERE id = $1
    `
	err = s.db.QueryRow(feesQuery, cartId).Scan(&orderDetails.ItemCost, &orderDetails.DeliveryFee, &orderDetails.PlatformFee, &orderDetails.SmallOrderFee, &orderDetails.RainFee, &orderDetails.HighTrafficSurcharge, &orderDetails.PackagingFee, &orderDetails.PeakTimeSurcharge, &orderDetails.Subtotal)
	if err != nil {
		return nil, fmt.Errorf("error getting fees and subtotal: %w", err)
	}

	// Query to fetch the customer's address
	addressQuery := `
        SELECT a.street_address
        FROM address a
        JOIN shopping_cart sc ON a.id = sc.address_id
        WHERE sc.id = $1
    `
	err = s.db.QueryRow(addressQuery, cartId).Scan(&orderDetails.Address)
	if err != nil {
		return nil, fmt.Errorf("error querying for address details: %w", err)
	}

	return orderDetails, nil
}

func (s *PostgresStore) CustomerPickupOrder(customerId, cartId int) (*PickupOrder, error) {
	query := `
    SELECT order_status
    FROM sales_order
    WHERE cart_id = $1 AND customer_id = $2
    `

	var orderStatus string
	err := s.db.QueryRow(query, cartId, customerId).Scan(&orderStatus)
	if err != nil {
		if err == sql.ErrNoRows {
			return &PickupOrder{Message: "No order found for this cart and customer.", Success: false}, nil
		}
		return nil, err
	}

	if orderStatus == "packed" {
		return &PickupOrder{Message: "Order is ready for pickup.", Success: true}, nil
	} else {
		return &PickupOrder{Message: "Order is not ready for pickup.", Success: false}, nil
	}
}

type PickupOrder struct {
	Message string `json:"message"`
	Success bool   `json:"success"`
}

type SalesOrderItem struct {
	ItemName             string    `json:"item_name"`
	UnitOfQuantity       string    `json:"unit_of_quantity"`
	Quantity             int       `json:"quantity"`
	SoldPrice            int       `json:"sold_price"`
	OrderDate            time.Time `json:"order_date"`
	Subtotal             int       `json:"subtotal"`
	DeliveryFee          int       `json:"delivery_fee"`
	PlatformFee          int       `json:"platform_fee"`
	SmallOrderFee        int       `json:"small_order_fee"`
	RainFee              int       `json:"rain_fee"`
	HighTrafficSurcharge int       `json:"high_traffic_surcharge"`
	PackingFee           int       `json:"packing_fee"`
}

func (s *PostgresStore) GetSalesOrderDetails(salesOrderID, customerID int) ([]*SalesOrderItem, error) {
	var salesOrderItems []*SalesOrderItem

	query := `
        SELECT i.name AS item_name, i.unit_of_quantity, ci.quantity, ci.sold_price, so.order_date, 
               sc.subtotal, sc.delivery_fee, sc.platform_fee, sc.small_order_fee, sc.rain_fee, 
               sc.high_traffic_surcharge, sc.packaging_fee
        FROM sales_order so
        JOIN shopping_cart sc ON so.cart_id = sc.id
        JOIN cart_item ci ON sc.id = ci.cart_id
        JOIN item_store istore ON ci.item_id = istore.id
        JOIN item i ON istore.item_id = i.id
        WHERE so.id = $1 AND so.customer_id = $2
    `

	rows, err := s.db.Query(query, salesOrderID, customerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var soi SalesOrderItem
		err := rows.Scan(
			&soi.ItemName,
			&soi.UnitOfQuantity,
			&soi.Quantity,
			&soi.SoldPrice,
			&soi.OrderDate,
			&soi.Subtotal,
			&soi.DeliveryFee,
			&soi.PlatformFee,
			&soi.SmallOrderFee,
			&soi.RainFee,
			&soi.HighTrafficSurcharge,
			&soi.PackingFee,
		)
		if err != nil {
			return nil, err
		}
		salesOrderItems = append(salesOrderItems, &soi)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return salesOrderItems, nil
}

// ... rest of the implementation remains the same

func (s *PostgresStore) Get_All_Sales_Orders() ([]*types.Sales_Order, error) {
	rows, err := s.db.Query("SELECT id, delivery_partner_id, cart_id, store_id, customer_id, address_id, paid, payment_type, order_date FROM sales_order")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var salesOrders []*types.Sales_Order

	for rows.Next() {
		var order types.Sales_Order
		if err := rows.Scan(&order.ID, &order.DeliveryPartnerID, &order.CartID, &order.StoreID, &order.CustomerID, &order.AddressID, &order.Paid, &order.PaymentType, &order.OrderDate); err != nil {
			return nil, fmt.Errorf("error scanning row: %v", err)
		}
		salesOrders = append(salesOrders, &order)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error reading rows: %v", err)
	}

	return salesOrders, nil
}

type OrderDetails struct {
	OrderID      int    `json:"order_id"`
	OrderDate    string `json:"order_date"`
	OrderAddress string `json:"order_address"`
	PaymentType  string `json:"payment_type"`
	PaidStatus   bool   `json:"paid_status"`
}

func (s *PostgresStore) GetOrdersByCustomerId(customer_id int) ([]OrderDetails, error) {
	var orders []OrderDetails

	// SQL query to fetch the required details
	query := `
        SELECT so.id,  so.order_date, CONCAT(a.street_address, ' ', a.line_one_address, ' ', a.line_two_address, ' ', a.city, ' ', a.state, ' ', a.zipcode), so.payment_type, so.paid
        FROM sales_order so
        JOIN address a ON so.address_id = a.id
        WHERE so.customer_id = $1
    `

	// Execute the query
	rows, err := s.db.Query(query, customer_id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Iterate through the result set
	for rows.Next() {
		var order OrderDetails
		err := rows.Scan(&order.OrderID, &order.OrderDate, &order.OrderAddress, &order.PaymentType, &order.PaidStatus)
		if err != nil {
			return nil, err
		}
		orders = append(orders, order)
	}

	// Check for errors from iterating over rows
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return orders, nil
}

func (s *PostgresStore) GetOrdersByDeliveryPartner(delivery_partner_id int) ([]*types.Sales_Order_Details, error) {
	query := `
        SELECT 
            so.id,
            so.delivery_partner_id,
            so.cart_id,
            so.store_id,
            st.name AS store_name,
            so.customer_id,
            cu.name AS customer_name,
            cu.phone AS customer_phone,
            so.delivery_address,
            so.order_date
        FROM sales_order so
        JOIN store st ON so.store_id = st.id
        JOIN customer cu ON so.customer_id = cu.id
        WHERE so.delivery_partner_id = $1
    `

	rows, err := s.db.Query(query, delivery_partner_id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var orders []*types.Sales_Order_Details
	for rows.Next() {
		var order types.Sales_Order_Details
		if err := rows.Scan(
			&order.ID,
			&order.DeliveryPartnerID,
			&order.CartID,
			&order.StoreID,
			&order.StoreName,
			&order.CustomerID,
			&order.CustomerName,
			&order.CustomerPhone,
			&order.DeliveryAddress,
			&order.OrderDate,
		); err != nil {
			return nil, err
		}
		orders = append(orders, &order)
	}

	return orders, nil
}

// needs to be implemented
func (s *PostgresStore) GetOldestOrderForStore(store_id int) (OrderDetails, error) {
	var order OrderDetails

	// SQL query to fetch the oldest order details
	query := `
        SELECT  so.order_date, CONCAT(a.street_address, ' ', a.line_one_address, ' ', a.line_two_address, ' ', a.city, ' ', a.state, ' ', a.zipcode), so.payment_type, so.paid
        FROM sales_order so
        JOIN address a ON so.address_id = a.id
        WHERE so.store_id = $1 AND so.order_status = 'received'
        ORDER BY so.order_date ASC
        LIMIT 1
    `

	// Execute the query
	row := s.db.QueryRow(query, store_id)
	err := row.Scan(&order.OrderDate, &order.OrderAddress, &order.PaymentType, &order.PaidStatus)
	if err != nil {
		return OrderDetails{}, err
	}

	return order, nil
}

// needs to be implemented
func (s *PostgresStore) GetReceivedOrdersForStore(store_id int) ([]OrderDetails, error) {
	var orders []OrderDetails

	// SQL query to fetch the orders
	query := `
        SELECT dp.name, so.order_date, CONCAT(a.street_address, ' ', a.line_one_address, ' ', a.line_two_address, ' ', a.city, ' ', a.state, ' ', a.zipcode), so.payment_type, so.paid
        FROM sales_order so
        JOIN address a ON so.address_id = a.id
        WHERE so.store_id = $1 AND so.order_status = 'received'
        ORDER BY so.order_date ASC
    `

	// Execute the query
	rows, err := s.db.Query(query, store_id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Iterate through the result set
	for rows.Next() {
		var order OrderDetails
		err := rows.Scan(&order.OrderDate, &order.OrderAddress, &order.PaymentType, &order.PaidStatus)
		if err != nil {
			return nil, err
		}
		orders = append(orders, order)
	}

	// Check for errors from iterating over rows
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return orders, nil
}

// needs to be implemented
func (s *PostgresStore) GetOrderItemsByStoreAndOrderId(orderId, storeId int) ([]ItemDetails, error) {
	var items []ItemDetails

	// SQL query to get the cart_id from the order
	orderQuery := `
        SELECT cart_id 
        FROM sales_order 
        WHERE id = $1 AND store_id = $2 AND order_status = 'accepted'
    `
	var cartId int
	err := s.db.QueryRow(orderQuery, orderId, storeId).Scan(&cartId)
	if err != nil {
		return nil, err
	}

	// SQL query to fetch item details
	itemQuery := `
        SELECT i.name, b.name, i.unit_of_quantity, i.quantity, ci.quantity, istore.mrp_price, array_agg(ii.image_url)
        FROM cart_item ci
        JOIN item_store istore ON ci.item_id = istore.id
        JOIN item i ON istore.item_id = i.id
        JOIN brand b ON i.brand_id = b.id
        LEFT JOIN item_image ii ON i.id = ii.item_id
        WHERE ci.cart_id = $1
        GROUP BY i.id, b.name, ci.quantity
        ORDER BY i.name
    `

	// Execute the query
	rows, err := s.db.Query(itemQuery, cartId)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Iterate through the result set
	for rows.Next() {
		var item ItemDetails
		var images []string
		err := rows.Scan(&item.Name, &item.Brand, &item.UnitOfQuantity, &item.Quantity, &item.StockQuantity, &item.MrpPrice, pq.Array(&images))
		if err != nil {
			return nil, err
		}
		item.Images = images
		items = append(items, item)
	}

	// Check for errors from iterating over rows
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

// needs to be implemented
type ItemDetails struct {
	Name           string   `json:"name"`
	Brand          string   `json:"brand"`
	UnitOfQuantity string   `json:"unit_of_quantity"` // Unit of measure (e.g., "g", "kg", "l")
	Quantity       int      `json:"quantity"`         // Numerical value of the unit (e.g., 100 in "100g")
	StockQuantity  int      `json:"stock_quantity"`   // Quantity of the item available in the cart
	MrpPrice       float64  `json:"mrp_price"`        // Maximum Retail Price of the item
	Images         []string `json:"images"`           // URLs of item images
}

func (s *PostgresStore) GetCombinedOrderDetails(storeId int, phoneNumber string) (CombinedOrderResponse, error) {
	var combinedResponse CombinedOrderResponse

	// Call PackOrder
	packedItems, err := s.PackOrder(storeId, phoneNumber)
	if err != nil {
		return combinedResponse, err
	}
	combinedResponse.PackedItems = packedItems

	// Retrieve packer_id from packer table using phoneNumber
	var packerId int
	packerIdQuery := `SELECT id FROM packer WHERE phone = $1`
	err = s.db.QueryRow(packerIdQuery, phoneNumber).Scan(&packerId)
	if err != nil {
		return combinedResponse, fmt.Errorf("error querying packer_id: %w", err)
	}

	// Assuming the order ID is available in the packed items list
	var orderId int
	if len(packedItems) > 0 {
		orderId = packedItems[0].Order_ID // Replace with correct field if necessary
	}

	// Call GetAllPackedItems
	packedDetails, err := s.GetAllPackedItems(phoneNumber, orderId)
	if err != nil {
		return combinedResponse, err
	}
	combinedResponse.PackedDetails = packedDetails

	// Calculate the sum of quantities of items needed
	sumNeeded := 0
	for _, item := range packedItems {
		sumNeeded += item.ItemQuantity
	}

	// Calculate the sum of quantities of items packed
	sumPacked := 0
	for _, detail := range packedDetails {
		sumPacked += detail.Quantity
	}

	// Check if all items are packed
	combinedResponse.AllPacked = sumNeeded == sumPacked

	return combinedResponse, nil
}

func (s *PostgresStore) PackOrder(storeId int, phoneNumber string) ([]PackedItem, error) {
	println("Entered PackOrder")
	var packerId int
	packerIdQuery := `SELECT id FROM packer WHERE phone = $1`
	err := s.db.QueryRow(packerIdQuery, phoneNumber).Scan(&packerId)
	if err != nil {
		return nil, fmt.Errorf("error finding packer ID: %w", err)
	}

	println("Checkpoint I")

	var existingOrderId int
	// Modified to check for 'received' or 'accepted' orders
	checkOrderQuery := `SELECT id FROM sales_order WHERE packer_id = $1 AND (order_status = 'accepted')`
	err = s.db.QueryRow(checkOrderQuery, packerId).Scan(&existingOrderId)
	if err == nil {
		items, err := s.fetchPackedItems(existingOrderId)
		println("Checkpoint II")

		if err != nil {
			return nil, fmt.Errorf("error fetching items for existing order: %w", err)
		}
		return items, nil
	} else if err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing orders: %w", err)
	}
	println("Checkpoint III")

	var orderId int
	// This query already handles switching from 'received' to 'accepted', no changes needed here
	combinedQuery := `
    UPDATE sales_order
    SET order_status = 'accepted', packer_id = $1
    WHERE id = (
        SELECT id FROM sales_order
        WHERE store_id = $2 AND (order_status = 'received')
        ORDER BY order_date ASC
        LIMIT 1
    )
    RETURNING id;
`

	err = s.db.QueryRow(combinedQuery, packerId, storeId).Scan(&orderId)
	if err != nil {
		return nil, fmt.Errorf("error retrieving and updating oldest order: %w", err)
	}

	// Fetching items for the updated order, no changes needed
	itemsQuery := `
        SELECT i.id, i.name, b.name, i.quantity, i.unit_of_quantity, ci.quantity, 
               s.horizontal, s.vertical
        FROM cart_item ci
        JOIN item i ON ci.item_id = i.id
        JOIN brand b ON i.brand_id = b.id
        LEFT JOIN shelf s ON i.id = s.item_id AND s.store_id = $2
        WHERE ci.cart_id = (SELECT cart_id FROM sales_order WHERE id = $1)
    `

	rows, err := s.db.Query(itemsQuery, orderId, storeId)
	if err != nil {
		return nil, fmt.Errorf("error fetching items: %w", err)
	}
	defer rows.Close()

	var packedItems []PackedItem
	for rows.Next() {
		var item PackedItem
		var horizontal sql.NullInt64
		var vertical sql.NullString
		if err := rows.Scan(&item.ItemID, &item.Name, &item.Brand, &item.Quantity, &item.UnitOfQuantity, &item.ItemQuantity, &horizontal, &vertical); err != nil {
			return nil, fmt.Errorf("error scanning items: %w", err)
		}

		if horizontal.Valid {
			item.ShelfHorizontal = new(int)
			*item.ShelfHorizontal = int(horizontal.Int64)
		}

		if vertical.Valid {
			item.ShelfVertical = new(string)
			*item.ShelfVertical = vertical.String
		}

		images, err := s.getItemImages(item.ItemID)
		if err != nil {
			return nil, err
		}
		item.ImageURLs = images
		item.Order_ID = orderId
		packedItems = append(packedItems, item)
	}

	return packedItems, nil
}

func (s *PostgresStore) fetchPackedItems(orderId int) ([]PackedItem, error) {
	itemsQuery := `
        SELECT i.id, i.name, b.name, i.quantity, i.unit_of_quantity, ci.quantity, 
               s.horizontal, s.vertical
        FROM cart_item ci
        JOIN item i ON ci.item_id = i.id
        JOIN brand b ON i.brand_id = b.id
        LEFT JOIN shelf s ON i.id = s.item_id AND s.store_id = (
            SELECT store_id FROM sales_order WHERE id = $1
        )
        WHERE ci.cart_id = (SELECT cart_id FROM sales_order WHERE id = $1)
    `
	rows, err := s.db.Query(itemsQuery, orderId)
	if err != nil {
		return nil, fmt.Errorf("error fetching items: %w", err)
	}
	defer rows.Close()

	var packedItems []PackedItem
	for rows.Next() {
		var item PackedItem
		var horizontal sql.NullInt64
		var vertical sql.NullString
		if err := rows.Scan(&item.ItemID, &item.Name, &item.Brand, &item.Quantity, &item.UnitOfQuantity, &item.ItemQuantity, &horizontal, &vertical); err != nil {
			return nil, fmt.Errorf("error scanning items: %w", err)
		}

		// Handling NULL values for shelf horizontal and vertical
		if horizontal.Valid {
			item.ShelfHorizontal = new(int)
			*item.ShelfHorizontal = int(horizontal.Int64)
		}

		if vertical.Valid {
			item.ShelfVertical = new(string)
			*item.ShelfVertical = vertical.String
		}

		images, err := s.getItemImages(item.ItemID)
		if err != nil {
			return nil, err
		}
		item.ImageURLs = images
		item.Order_ID = orderId
		packedItems = append(packedItems, item)
	}

	return packedItems, nil
}

// getItemImages fetches all images for a given item
func (s *PostgresStore) getItemImages(itemId int) ([]string, error) {
	query := `SELECT image_url FROM item_image WHERE item_id = $1 ORDER BY order_position`
	rows, err := s.db.Query(query, itemId)
	if err != nil {
		return nil, fmt.Errorf("error fetching item images: %w", err)
	}
	defer rows.Close()

	var images []string
	for rows.Next() {
		var imageUrl string
		if err := rows.Scan(&imageUrl); err != nil {
			return nil, fmt.Errorf("error scanning image url: %w", err)
		}
		images = append(images, imageUrl)
	}

	return images, nil
}

// PackedItem represents the structure of an item in the packed order
type PackedItem struct {
	ItemID          int      `json:"item_id"`
	Order_ID        int      `json:"order_id"`
	Name            string   `json:"name"`
	Brand           string   `json:"brand"`
	Quantity        int      `json:"quantity"`
	UnitOfQuantity  string   `json:"unit_of_quantity"`
	ItemQuantity    int      `json:"item_quantity"`
	ShelfHorizontal *int     `json:"shelf_horizontal"` // Pointer to handle NULLs
	ShelfVertical   *string  `json:"shelf_vertical"`   // Pointer to handle NULLs
	ImageURLs       []string `json:"image_urls"`
}

func (s *PostgresStore) PackerOrderAllocateSpace(req types.SpaceOrder) (AllocationInfo, error) {
	var info AllocationInfo

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return info, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback() // Rollback transaction in case of any error

	// 1. Find delivery_shelf using horizontal, vertical, and store_id
	var deliveryShelfID int
	deliveryShelfQuery := `SELECT id FROM delivery_shelf WHERE location = $1 AND store_id = $2`
	err = tx.QueryRow(deliveryShelfQuery, req.Location, req.StoreId).Scan(&deliveryShelfID)
	if err != nil {
		return info, fmt.Errorf("error finding delivery shelf: %w", err)
	}

	// 2. Insert into Packer_Shelf
	packerShelfQuery := `
		INSERT INTO Packer_Shelf (sales_order_id, packer_id, delivery_shelf_id, image_url, active)
		VALUES ($1, (SELECT id FROM Packer WHERE phone = $2), $3, $4, true)`
	_, err = tx.Exec(packerShelfQuery, req.SalesOrderID, req.PackerPhone, deliveryShelfID, req.Image)
	if err != nil {
		return info, fmt.Errorf("error inserting into Packer_Shelf: %w", err)
	}

	orderStatusQuery := `UPDATE sales_order SET order_status = 'packed' WHERE id = $1 AND (order_status = 'accepted' OR order_status = 'received')`
	_, err = tx.Exec(orderStatusQuery, req.SalesOrderID)
	if err != nil {
		return info, fmt.Errorf("error updating sales_order status: %w", err)
	}
	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		return info, fmt.Errorf("error committing transaction: %w", err)
	}

	// Set return values
	info = AllocationInfo{
		SalesOrderID: req.SalesOrderID,
		Location:     req.Location,
		ShelfID:      deliveryShelfID,
		Image:        req.Image,
	}

	return info, nil
}

// Modified AllocationInfo struct
type AllocationInfo struct {
	SalesOrderID int    `json:"sales_order_id"`
	Location     int    `json:"location"`
	ShelfID      int    `json:"shelf_id"`
	Image        string `json:"image"`
}

func (s *PostgresStore) CancelPackOrder(storeId int, phoneNumber string, orderId int) (bool, error) {
	var packerId int
	packerIdQuery := `SELECT id FROM packer WHERE phone = $1`
	err := s.db.QueryRow(packerIdQuery, phoneNumber).Scan(&packerId)
	if err != nil {
		return false, fmt.Errorf("error finding packer ID: %w", err)
	}

	// Step 2: Reverse the sales_order status from 'accepted' to 'received'
	updateQuery := `
        UPDATE sales_order
        SET order_status = 'received'
        WHERE id = $1 AND store_id = $2 AND packer_id = $3 AND order_status = 'accepted'
        RETURNING id;
    `
	var updatedOrderId int
	err = s.db.QueryRow(updateQuery, orderId, storeId, packerId).Scan(&updatedOrderId)
	if err != nil {
		// If no rows are affected, it might not necessarily be an error.
		// It could be that no order met the criteria.
		if err == sql.ErrNoRows {
			return false, nil // No order was updated.
		}
		return false, fmt.Errorf("error updating order status: %w", err)
	}

	// Check if the update was successful
	if updatedOrderId == orderId {
		return true, nil // The order was successfully updated.
	}

	return false, nil // No order was updated.
}

type CombinedOrderResponse struct {
	PackedItems   []PackedItem       `json:"packed_items"`
	PackedDetails []PackerItemDetail `json:"packed_details"`
	AllPacked     bool               `json:"all_packed"`
}

type CheckForPlacedOrder struct {
	CartId int    `json:"cart_id"`
	Status string `json:"status"`
}

func (s *PostgresStore) CheckForPlacedOrder(phone string) (CheckForPlacedOrder, error) {
	var order CheckForPlacedOrder
	query := `
        SELECT cart_id, order_status 
        FROM sales_order
        WHERE customer_id = (SELECT id FROM customer WHERE phone = $1)
          AND order_status NOT IN ('completed')
        ORDER BY order_date DESC
        LIMIT 1
    `
	err := s.db.QueryRow(query, phone).Scan(&order.CartId, &order.Status)
	if err != nil {
		return order, err
	}
	return order, nil
}

func (s *PostgresStore) GetOrderDetails(orderID int) ([]OrderDetail, error) {
	query := `
    SELECT i.name, ci.quantity, i.quantity, i.unit_of_quantity, so.order_date
    FROM sales_order so
    JOIN cart_item ci ON so.cart_id = ci.cart_id
    JOIN item i ON ci.item_id = i.id
    WHERE so.id = $1
    `

	rows, err := s.db.Query(query, orderID)
	if err != nil {
		return nil, fmt.Errorf("error querying order details: %w", err)
	}
	defer rows.Close()

	var details []OrderDetail
	for rows.Next() {
		var detail OrderDetail
		err := rows.Scan(&detail.ItemName, &detail.ItemQuantity, &detail.ItemSize, &detail.UnitOfQuantity, &detail.OrderPlacedTime)
		if err != nil {
			return nil, fmt.Errorf("error scanning order detail: %w", err)
		}
		details = append(details, detail)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating through order details results: %w", err)
	}

	return details, nil
}

func (s *PostgresStore) GetOrderDetailsCustomer(orderId int, customerId int) (*OrderDetailCustomer, error) {
	itemQuery := `
	SELECT i.name, ci.quantity, i.quantity, i.unit_of_quantity
	FROM sales_order so
	JOIN cart_item ci ON so.cart_id = ci.cart_id
	JOIN item i ON ci.item_id = i.id
	WHERE so.id = $1 AND so.customer_id = $2
	`

	feesQuery := `
	SELECT sc.item_cost, sc.delivery_fee, sc.platform_fee, sc.small_order_fee, sc.rain_fee, sc.high_traffic_surcharge, sc.packaging_fee, sc.peak_time_surcharge, sc.subtotal, sc.discounts, so.order_date
	FROM sales_order so
	JOIN shopping_cart sc ON so.cart_id = sc.id
	WHERE so.id = $1 AND so.customer_id = $2
	LIMIT 1
	`

	// Initialize orderDetails
	orderDetails := &OrderDetailCustomer{
		Items: make([]ItemDetail, 0), // Ensure Items slice is initialized
	}

	// Execute item details query
	itemRows, err := s.db.Query(itemQuery, orderId, customerId)
	if err != nil {
		return nil, err // Error handling
	}
	defer itemRows.Close()

	for itemRows.Next() {
		var item ItemDetail
		if err := itemRows.Scan(&item.ItemName, &item.ItemQuantity, &item.ItemSize, &item.UnitOfQuantity); err != nil {
			return nil, err // Error handling
		}
		orderDetails.Items = append(orderDetails.Items, item)
	}

	// Execute fees query
	feesRow := s.db.QueryRow(feesQuery, orderId, customerId)
	if err := feesRow.Scan(&orderDetails.Fees.ItemCost, &orderDetails.Fees.DeliveryFee, &orderDetails.Fees.PlatformFee, &orderDetails.Fees.SmallOrderFee, &orderDetails.Fees.RainFee, &orderDetails.Fees.HighTrafficSurcharge, &orderDetails.Fees.PackagingFee, &orderDetails.Fees.PeakTimeSurcharge, &orderDetails.Fees.Subtotal, &orderDetails.Fees.Discounts, &orderDetails.OrderPlacedTime); err != nil {
		return nil, err // Error handling
	}

	return orderDetails, nil
}

type ItemDetail struct {
	ItemName       string `json:"itemName"`
	ItemQuantity   int    `json:"itemQuantity"` // This is the quantity from the cart_item table
	ItemSize       int    `json:"itemSize"`     // This represents the size from the item table
	UnitOfQuantity string `json:"unitOfQuantity"`
}

type ShoppingCartFees struct {
	ItemCost             int `json:"itemCost"`
	DeliveryFee          int `json:"deliveryFee"`
	PlatformFee          int `json:"platformFee"`
	SmallOrderFee        int `json:"smallOrderFee"`
	RainFee              int `json:"rainFee"`
	HighTrafficSurcharge int `json:"highTrafficSurcharge"`
	PackagingFee         int `json:"packagingFee"`
	PeakTimeSurcharge    int `json:"peakTimeSurcharge"`
	Subtotal             int `json:"subtotal"`
	Discounts            int `json:"discounts"`
}

type OrderDetailCustomer struct {
	OrderPlacedTime time.Time        `json:"orderPlacedTime"`
	Items           []ItemDetail     `json:"items"`
	Fees            ShoppingCartFees `json:"fees"`
}

type OrderDetail struct {
	ItemName        string
	ItemQuantity    int // This is the quantity from the cart_item table
	ItemSize        int // This represents the size from the item table
	UnitOfQuantity  string
	OrderPlacedTime time.Time
}
