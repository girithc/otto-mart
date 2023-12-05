package store

import (
	"database/sql"
	"fmt"

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
		order_dp_status dp_status DEFAULT 'pending'
    )`

	_, err = tx.Exec(query)
	return err
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
	// SQL query to fetch the most recent sales order for specific customer, store, and cart
	query := `SELECT id, delivery_partner_id, cart_id, store_id, customer_id, address_id, paid, payment_type, order_date
              FROM sales_order
              WHERE customer_id = $1 AND store_id = $2 AND cart_id = $3
              ORDER BY order_date DESC
              LIMIT 1`

	// Execute the query
	var so types.Sales_Order_Cart
	err := s.db.QueryRow(query, customerID, storeID, cartID).Scan(&so.ID, &so.DeliveryPartnerID, &so.CartID, &so.StoreID, &so.CustomerID, &so.AddressID, &so.Paid, &so.PaymentType, &so.OrderDate)
	if err != nil {
		return nil, err
	}

	shoppingCartQuery := `SELECT id FROM shopping_cart WHERE customer_id = $1 AND active = true`

	// Execute the shopping cart query
	err = s.db.QueryRow(shoppingCartQuery, customerID).Scan(&so.NewCartID)
	if err != nil {
		return nil, err
	}

	deliveryPartnerQuery := `SELECT id, name, fcm_token, store_id, phone, address, created_at, available, current_location, active_deliveries, last_assigned_time
                         FROM delivery_partner
                         WHERE id = $1`
	// Execute the delivery partner query
	var dp types.SODeliveryPartner
	err = s.db.QueryRow(deliveryPartnerQuery, so.DeliveryPartnerID).Scan(&dp.ID, &dp.Name, &dp.FcmToken, &dp.StoreID, &dp.Phone, &dp.Address, &dp.CreatedAt, &dp.Available, &dp.CurrentLocation, &dp.ActiveDeliveries, &dp.LastAssignedTime)
	if err != nil {
		return nil, err
	}
	so.DeliveryPartner = dp

	productListQuery := `SELECT ci.id, ci.item_id, ci.quantity, i.name, i.brand_id, i.quantity AS item_quantity, i.unit_of_quantity, i.description
                     FROM cart_item ci
                     JOIN item i ON ci.item_id = i.id
                     WHERE ci.cart_id = $1`
	// Execute the product list query
	rows, err := s.db.Query(productListQuery, so.CartID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var products []types.SOProduct
	for rows.Next() {
		var p types.SOProduct
		err := rows.Scan(&p.ID, &p.ItemID, &p.Quantity, &p.Name, &p.BrandID, &p.ItemQuantity, &p.UnitOfQuantity, &p.Description)
		if err != nil {
			return nil, err
		}
		products = append(products, p)
	}
	so.Products = products

	storeQuery := `SELECT id, name, address FROM store WHERE id = $1`
	var store types.SOStore
	err = s.db.QueryRow(storeQuery, so.StoreID).Scan(&store.ID, &store.Name, &store.Address)
	if err != nil {
		return nil, err
	}
	so.Store = store

	addressQuery := `SELECT id, latitude, longitude, street_address, line_one_address, line_two_address, city, state, zipcode, is_default
                 FROM address
                 WHERE id = $1`
	var address types.SOAddress
	err = s.db.QueryRow(addressQuery, so.AddressID).Scan(&address.ID, &address.Latitude, &address.Longitude, &address.StreetAddress, &address.LineOneAddress, &address.LineTwoAddress, &address.City, &address.State, &address.Zipcode, &address.IsDefault)
	if err != nil {
		return nil, err
	}
	so.Address = address

	// Combine the sales order and shopping cart ID in the result

	return &so, nil
}

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
	DeliveryPartnerName string `json:"delivery_partner_name"`
	OrderDate           string `json:"order_date"`
	OrderAddress        string `json:"order_address"`
	PaymentType         string `json:"payment_type"`
	PaidStatus          bool   `json:"paid_status"`
}

func (s *PostgresStore) GetOrdersByCustomerId(customer_id int) ([]OrderDetails, error) {
	var orders []OrderDetails

	// SQL query to fetch the required details
	query := `
        SELECT dp.name, so.order_date, CONCAT(a.street_address, ' ', a.line_one_address, ' ', a.line_two_address, ' ', a.city, ' ', a.state, ' ', a.zipcode), so.payment_type, so.paid
        FROM sales_order so
        JOIN address a ON so.address_id = a.id
        JOIN delivery_partner dp ON so.delivery_partner_id = dp.id
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
		err := rows.Scan(&order.DeliveryPartnerName, &order.OrderDate, &order.OrderAddress, &order.PaymentType, &order.PaidStatus)
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
        SELECT dp.name, so.order_date, CONCAT(a.street_address, ' ', a.line_one_address, ' ', a.line_two_address, ' ', a.city, ' ', a.state, ' ', a.zipcode), so.payment_type, so.paid
        FROM sales_order so
        JOIN address a ON so.address_id = a.id
        JOIN delivery_partner dp ON so.delivery_partner_id = dp.id
        WHERE so.store_id = $1 AND so.order_status = 'received'
        ORDER BY so.order_date ASC
        LIMIT 1
    `

	// Execute the query
	row := s.db.QueryRow(query, store_id)
	err := row.Scan(&order.DeliveryPartnerName, &order.OrderDate, &order.OrderAddress, &order.PaymentType, &order.PaidStatus)
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
        JOIN delivery_partner dp ON so.delivery_partner_id = dp.id
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
		err := rows.Scan(&order.DeliveryPartnerName, &order.OrderDate, &order.OrderAddress, &order.PaymentType, &order.PaidStatus)
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
