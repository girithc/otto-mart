package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateSalesOrderTable(tx *sql.Tx) error {
	// Define the ENUM type for payment_type
	paymentTypeQuery := `DO $$ BEGIN
        CREATE TYPE payment_method AS ENUM ('cash', 'credit card', 'debit card', 'upi');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err := tx.Exec(paymentTypeQuery)
	if err != nil {
		return err
	}

	// Create the sales_order table
	query := `create table if not exists sales_order (
        id SERIAL PRIMARY KEY,
        delivery_partner_id INT REFERENCES Delivery_Partner(id) ON DELETE CASCADE,
        cart_id INT REFERENCES Shopping_Cart(id) ON DELETE CASCADE NOT NULL,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
        address_id INT REFERENCES Address(id) ON DELETE CASCADE NOT NULL,
        paid BOOLEAN NOT NULL DEFAULT false,
        payment_type payment_method DEFAULT 'cash',
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err = tx.Exec(query)
	return err
}

func (s *PostgresStore) GetRecentSalesOrder(customerID, storeID, cartID int) (*types.Sales_Order_Cart, error) {
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
