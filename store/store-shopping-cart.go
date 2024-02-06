package store

import (
	"database/sql"
	"time"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable(tx *sql.Tx) error {
	// Create the shopping_cart table
	createTableQuery := `
        CREATE TABLE IF NOT EXISTS shopping_cart (
            id SERIAL PRIMARY KEY,
            customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
            order_id INT, 
            store_id INT REFERENCES Store(id) ON DELETE CASCADE,
            active BOOLEAN NOT NULL DEFAULT true,
            address_id INT REFERENCES Address(id) ON DELETE SET NULL,
            item_cost INT DEFAULT 0,
            delivery_fee INT DEFAULT 0,
            platform_fee INT DEFAULT 0,
            small_order_fee INT DEFAULT 0,
            rain_fee INT DEFAULT 0,
            high_traffic_surcharge INT DEFAULT 0,
            packaging_fee INT DEFAULT 0,
            peak_time_surcharge INT DEFAULT 0,
			number_of_items INT DEFAULT 0,
            subtotal INT GENERATED ALWAYS AS (
                item_cost + delivery_fee + platform_fee + small_order_fee + 
                rain_fee + high_traffic_surcharge + peak_time_surcharge + packaging_fee
            ) STORED,
            discounts INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`

	_, err := tx.Exec(createTableQuery)
	if err != nil {
		return err
	}

	return nil
}

func (s *PostgresStore) SetShoppingCartForeignKey(tx *sql.Tx) error {
	// Add foreign key constraint to the already created table
	query := `
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT constraint_name 
            FROM information_schema.table_constraints 
            WHERE table_name = 'shopping_cart' AND constraint_name = 'shopping_cart_order_id_fkey'
        ) THEN
            ALTER TABLE shopping_cart ADD CONSTRAINT shopping_cart_order_id_fkey FOREIGN KEY (order_id) REFERENCES sales_order(id) ON DELETE CASCADE;
        END IF;
    END
    $$;
    `

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
	var itemCost, discounts, numberOfItems, deliveryFee, smallOrderFee, platformFee, packagingFee int

	// Calculate total item cost and discounts from cart_item and item_store
	query := `
	SELECT 
		COALESCE(SUM(ci.sold_price * ci.quantity), 0),
		COALESCE(SUM(ci.quantity), 0),  
		COALESCE(SUM((istore.mrp_price - ci.sold_price) * ci.quantity), 0)
	FROM cart_item ci
	JOIN item_store istore ON ci.item_id = istore.id
	WHERE ci.cart_id = $1`

	err := s.db.QueryRow(query, cart_id).Scan(&itemCost, &numberOfItems, &discounts)
	if err != nil {
		return err
	}

	// Calculate delivery fee based on item cost
	switch {
	case itemCost <= 99:
		deliveryFee = 39
	case itemCost <= 249:
		deliveryFee = 29
	case itemCost <= 399:
		deliveryFee = 19
	default:
		deliveryFee = 9
	}

	// Calculate small order fee based on item cost
	switch {
	case itemCost <= 99:
		smallOrderFee = 29
	case itemCost <= 249:
		smallOrderFee = 19
	case itemCost <= 399:
		smallOrderFee = 9
	default:
		smallOrderFee = 0
	}

	switch {
	case itemCost > 999:
		platformFee = 9
	case itemCost > 399:
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
        packaging_fee = $6, discounts = $7, number_of_items = $8
    WHERE id = $1`
	_, err = s.db.Exec(updateQuery, cart_id, itemCost, deliveryFee, platformFee, smallOrderFee, packagingFee, discounts, numberOfItems)
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

	// Define variables for all columns in the shopping_cart table
	var (
		orderID sql.NullInt64
		storeID sql.NullInt64
		address sql.NullString
		itemCost, deliveryFee, platformFee, smallOrderFee, rainFee,
		highTrafficSurcharge, packagingFee, peakTimeSurcharge, numberOfItems,
		subtotal, discounts int
		createdAt time.Time
	)

	err := rows.Scan(
		&cart.ID,
		&cart.Customer_Id,
		&orderID,
		&storeID,
		&cart.Active,
		&address,
		&itemCost,
		&deliveryFee,
		&platformFee,
		&smallOrderFee,
		&rainFee,
		&highTrafficSurcharge,
		&packagingFee,
		&peakTimeSurcharge,
		&numberOfItems,
		&subtotal,
		&discounts,
		&createdAt,
	)

	// Set values for nullable fields
	if orderID.Valid {
		cart.Order_Id = int(orderID.Int64)
	}
	if storeID.Valid {
		cart.Store_Id = int(storeID.Int64)
	}
	if address.Valid {
		cart.Address = address.String
	}
	// Add the additional fields to the cart struct
	cart.Created_At = createdAt

	return cart, err
}

type ValidShoppingCart struct {
	Valid  bool
	CartId int
}

func (s *PostgresStore) ValidShoppingCart(cartID int, customerID int) (ValidShoppingCart, error) {
	var count int
	val := ValidShoppingCart{false, 0}
	// Check if the provided cartID is valid and belongs to the customerID
	err := s.db.QueryRow("SELECT COUNT(*) FROM shopping_cart WHERE id = $1 AND customer_id = $2 AND active = true", cartID, customerID).Scan(&count)
	if err != nil {
		return val, err
	}

	// If the cartID is valid and belongs to the customer, return the cartID
	if count > 0 {
		val.CartId = cartID
		val.Valid = true
		return val, nil
	}

	// If the provided cartID is not valid, check for any existing active cart for the customer
	var existingCartID int
	err = s.db.QueryRow("SELECT id FROM shopping_cart WHERE customer_id = $1 AND active = true LIMIT 1", customerID).Scan(&existingCartID)
	if err == nil {
		// An active cart exists, return its ID
		val.CartId = existingCartID
		val.Valid = true
		return val, nil
	}

	// No active cart exists for the customer, create a new one
	var newCartID int
	err = s.db.QueryRow(`INSERT INTO shopping_cart (customer_id, active) VALUES ($1, true) RETURNING id`, customerID).Scan(&newCartID)
	if err != nil {
		return val, err
	}

	// Return the new cart ID
	val.CartId = newCartID
	val.Valid = true
	return val, nil
}
