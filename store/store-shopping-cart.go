package store

import (
	"database/sql"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable(tx *sql.Tx) error {
	query := `
        CREATE TABLE IF NOT EXISTS shopping_cart (
            id SERIAL PRIMARY KEY,
            customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
            order_id INT, 
            store_id INT REFERENCES Store(id) ON DELETE CASCADE,
            active BOOLEAN NOT NULL DEFAULT true,
			address_id INT REFERENCES Address(id) ON DELETE SET NULL,
            item_cost DECIMAL(10, 2) DEFAULT 0,
            delivery_fee DECIMAL(10, 2) DEFAULT 0,
            platform_fee DECIMAL(10, 2) DEFAULT 0,
            small_order_fee DECIMAL(10, 2) DEFAULT 0,
            rain_fee DECIMAL(10, 2) DEFAULT 0,
            high_traffic_surcharge DECIMAL(10, 2) DEFAULT 0,
            packaging_fee DECIMAL(10, 2) DEFAULT 0,
            peak_time_surcharge DECIMAL(10, 2) DEFAULT 0,
            subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (
                item_cost + delivery_fee + platform_fee + small_order_fee + 
                rain_fee + high_traffic_surcharge + peak_time_surcharge + packaging_fee
            ) STORED,
            discounts DECIMAL(10, 2) DEFAULT 0,
            total DECIMAL(10, 2) GENERATED ALWAYS AS (subtotal - discounts) STORED,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`
	_, err := tx.Exec(query)
	return err
}

func (s *PostgresStore) Create_Shopping_Cart(cart *types.Create_Shopping_Cart) (*types.Shopping_Cart, error) {
	query := `insert into shopping_cart
	(customer_id, active) 
	values ($1, $2) returning id, customer_id, active, created_at
	`
	rows, err := s.db.Query(
		query,
		cart.Customer_Id,
		true,
	)
	if err != nil {
		return nil, err
	}

	shopping_carts := []*types.Shopping_Cart{}

	for rows.Next() {
		shopping_cart, err := scan_Into_Shopping_Cart(rows)
		if err != nil {
			return nil, err
		}
		shopping_carts = append(shopping_carts, shopping_cart)
	}

	return shopping_carts[0], nil
}

func (s *PostgresStore) CalculateCartTotal(cart_id int) error {
	var itemCost, discounts, deliveryFee, smallOrderFee, platformFee, packagingFee float64

	// Calculate total item cost and discounts from cart_item and item_store
	query := `
    SELECT SUM(ci.sold_price * ci.quantity), SUM((istore.mrp_price - ci.sold_price) * ci.quantity)
    FROM cart_item ci
    JOIN item_store istore ON ci.item_id = is.id
    WHERE ci.cart_id = $1`
	err := s.db.QueryRow(query, cart_id).Scan(&itemCost, &discounts)
	if err != nil {
		return err
	}

	// Calculate delivery fee based on item cost
	switch {
	case itemCost <= 99:
		deliveryFee = 29
	case itemCost <= 199:
		deliveryFee = 19
	case itemCost <= 299:
		deliveryFee = 9
	default:
		deliveryFee = 0
	}

	// Calculate small order fee based on item cost
	switch {
	case itemCost <= 99:
		smallOrderFee = 29
	case itemCost <= 199:
		smallOrderFee = 19
	case itemCost <= 299:
		smallOrderFee = 9
	default:
		smallOrderFee = 0
	}

	switch {
	case itemCost > 999:
		platformFee = 9
	case itemCost > 299:
		platformFee = 5
	default:
		platformFee = 3
	}

	// Calculate packaging fee based on item cost
	switch {
	case itemCost > 999:
		packagingFee = 9
	case itemCost > 399:
		packagingFee = 5
	default:
		packagingFee = 2
	}

	// Update shopping_cart record
	updateQuery := `
    UPDATE shopping_cart
    SET item_cost = $2, delivery_fee = $3, platform_fee = $4, small_order_fee = $5, 
        packaging_fee = $6, discounts = $7
    WHERE id = $1`
	_, err = s.db.Exec(updateQuery, cart_id, itemCost, deliveryFee, platformFee, smallOrderFee, packagingFee, discounts)
	return err
}

func (s *PostgresStore) Get_All_Active_Shopping_Carts() ([]*types.Shopping_Cart, error) {
	rows, err := s.db.Query("select * from shopping_cart where active = $1", true)
	if err != nil {
		return nil, err
	}

	shopping_carts := []*types.Shopping_Cart{}

	for rows.Next() {
		shopping_cart, err := scan_Into_Shopping_Cart(rows)
		if err != nil {
			return nil, err
		}
		shopping_carts = append(shopping_carts, shopping_cart)
	}

	return shopping_carts, nil
}

func (s *PostgresStore) Get_Shopping_Cart_By_Customer_Id(customer_id int, active bool) (*types.Shopping_Cart, error) {
	rows, err := s.db.Query("select * from shopping_cart where active = $1 and customer_id = $2", active, customer_id)
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		return scan_Into_Shopping_Cart(rows)
	}

	return nil, nil
}

func (s *PostgresStore) DoesCartExist(cartID int) (bool, error) {
	var count int
	err := s.db.QueryRow("SELECT COUNT(*) FROM shopping_cart WHERE id = $1 AND active = true", cartID).Scan(&count)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

func scan_Into_Shopping_Cart(rows *sql.Rows) (*types.Shopping_Cart, error) {
	cart := new(types.Shopping_Cart)

	// Use sql.NullInt64 for order_id and store_id to handle NULL values
	var orderID sql.NullInt64
	var storeID sql.NullInt64
	// Use sql.NullString for address to handle NULL values
	var address sql.NullString

	err := rows.Scan(
		&cart.ID,
		&cart.Customer_Id,
		&orderID,
		&storeID,
		&cart.Active,
		&address, // Scan into sql.NullString variable
		&cart.Created_At,
	)

	// If orderID has a valid value (i.e., it's not NULL), set it to cart.Order_Id
	if orderID.Valid {
		cart.Order_Id = int(orderID.Int64)
	}
	if storeID.Valid {
		cart.Store_Id = int(storeID.Int64)
	}
	// If address has a valid value (i.e., it's not NULL), set it to cart.Address
	if address.Valid {
		cart.Address = address.String
	}

	return cart, err
}
