package store

import (
	"database/sql"
	"math"
	"time"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateShoppingCartTable(tx *sql.Tx) error {
	orderTypeQuery := `DO $$ BEGIN
        CREATE TYPE order_type AS ENUM ('delivery');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;`

	_, err := tx.Exec(orderTypeQuery)
	if err != nil {
		return err
	}

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

	_, err = tx.Exec(createTableQuery)
	if err != nil {
		return err
	}

	// Step 1: Update existing records
	updateQuery := `UPDATE shopping_cart SET store_id = 1 WHERE store_id IS NULL`
	_, err = tx.Exec(updateQuery)
	if err != nil {
		return err
	}

	// Step 2: Alter the column to not allow NULL and ensure the default value is 1
	alterTableQuery := `ALTER TABLE shopping_cart
                       ALTER COLUMN store_id SET NOT NULL,
                        ALTER COLUMN store_id SET DEFAULT 1;`
	_, err = tx.Exec(alterTableQuery)
	if err != nil {
		return err
	}

	alterTableQuery = `ALTER TABLE shopping_cart
        ADD COLUMN IF NOT EXISTS order_type order_type DEFAULT 'delivery';`

	_, err = tx.Exec(alterTableQuery)
	if err != nil {
		return err
	}

	alterTableQuery = `ALTER TABLE shopping_cart
        ADD COLUMN IF NOT EXISTS slot_id INT REFERENCES slot(id) ON DELETE SET NULL,
        ADD COLUMN IF NOT EXISTS delivery_date DATE;`

	_, err = tx.Exec(alterTableQuery)
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

func (s *PostgresStore) CreateSlotTable(tx *sql.Tx) error {
	createTableQuery := `
        CREATE TABLE IF NOT EXISTS slot (
            id SERIAL PRIMARY KEY,
            start_time TIME NOT NULL,
            end_time TIME NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(start_time, end_time)
        )`

	_, err := tx.Exec(createTableQuery)
	if err != nil {
		return err
	}

	// Create an index on start_time and end_time for more efficient querying
	createIndexQuery := `CREATE INDEX IF NOT EXISTS idx_slot_times ON slot(start_time, end_time);`
	_, err = tx.Exec(createIndexQuery)
	if err != nil {
		return err
	}

	// Define your time slots here
	slots := []struct {
		StartTime string
		EndTime   string
	}{
		{"06:00:00", "08:00:00"},
		{"08:00:00", "10:00:00"},
		{"10:00:00", "12:00:00"},
	}

	for _, slot := range slots {
		insertSlotQuery := `INSERT INTO slot (start_time, end_time) 
                            VALUES ($1::TIME, $2::TIME) 
                            ON CONFLICT DO NOTHING`
		_, err := tx.Exec(insertSlotQuery, slot.StartTime, slot.EndTime)
		if err != nil {
			return err
		}
	}

	return nil
}

func (s *PostgresStore) CreateDeliveryDistanceTable(tx *sql.Tx) error {
	createTableQuery := `
        CREATE TABLE IF NOT EXISTS delivery_distance (
            id SERIAL PRIMARY KEY,
            min_distance DECIMAL(10, 2) NOT NULL,
            max_distance DECIMAL(10, 2) NOT NULL,
            min_delivery_amount INT NOT NULL,
            CONSTRAINT distance_check CHECK (min_distance < max_distance),
            UNIQUE(min_distance, max_distance)
        )`

	_, err := tx.Exec(createTableQuery)
	if err != nil {
		return err
	}

	// Alter min_distance and max_distance columns to DECIMAL(10, 2) if needed
	alterDistanceColumnsQuery := `
        ALTER TABLE delivery_distance
        ALTER COLUMN min_distance TYPE DECIMAL(10, 2),
        ALTER COLUMN max_distance TYPE DECIMAL(10, 2)`

	_, err = tx.Exec(alterDistanceColumnsQuery)
	if err != nil {
		return err
	}

	// Alter min_delivery_amount column to INT if needed
	alterDeliveryAmountColumnQuery := `
        ALTER TABLE delivery_distance
        ALTER COLUMN min_delivery_amount TYPE INT`

	_, err = tx.Exec(alterDeliveryAmountColumnQuery)
	if err != nil {
		return err
	}

	return nil
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
	print("Calculating cart total for cart_id: ", cart_id)
	var itemCost, discounts, numberOfItems, deliveryFee, smallOrderFee, platformFee, packagingFee float64 // Changed to float64 to handle decimal values

	var orderType string

	// Fetch the order type for the cart
	orderTypeQuery := `SELECT order_type FROM shopping_cart WHERE id = $1`
	err := s.db.QueryRow(orderTypeQuery, cart_id).Scan(&orderType)
	if err != nil {
		return err
	}

	var addressId int
	addressQuery := `SELECT address_id FROM shopping_cart WHERE id = $1`
	err = s.db.QueryRow(addressQuery, cart_id).Scan(&addressId)
	if err != nil {
		return err
	}

	var distanceToStore float64
	distanceQuery := `SELECT distance_to_store FROM address WHERE id = $1`
	err = s.db.QueryRow(distanceQuery, addressId).Scan(&distanceToStore)
	if err != nil {
		return err
	}

	var minDeliveryAmount int
	minDeliveryAmountQuery := `SELECT min_delivery_amount FROM delivery_distance WHERE $1 > min_distance AND $1 <= max_distance`
	err = s.db.QueryRow(minDeliveryAmountQuery, distanceToStore).Scan(&minDeliveryAmount)
	if err != nil {
		return err
	}

	// Calculate total item cost and discounts from cart_item and item_store
	query := `
    SELECT 
        COALESCE(SUM(CAST(ci.sold_price AS DECIMAL(10, 2)) * ci.quantity), 0), 
        COALESCE(SUM(ci.quantity), 0),  
        COALESCE(SUM((ifin.mrp_price - CAST(ci.sold_price AS DECIMAL(10, 2))) * ci.quantity), 0)
    FROM cart_item ci
    JOIN item_financial ifin ON ci.item_id = ifin.item_id
    WHERE ci.cart_id = $1`

	err = s.db.QueryRow(query, cart_id).Scan(&itemCost, &numberOfItems, &discounts)
	if err != nil {
		return err
	}

	platformFee = math.Max(2, math.Round(float64(itemCost)*0.01))

	if orderType == "delivery" {
		switch {
		case itemCost >= float64(minDeliveryAmount):
			deliveryFee = 0
			smallOrderFee = 0

		default:
			deliveryFee = 35
			smallOrderFee = 35
		}

		switch {
		default:
			packagingFee = 0
		}
	} else {

		smallOrderFee = 0
		platformFee = 0
		packagingFee = 0
	}

	subtotal := itemCost + deliveryFee + platformFee + smallOrderFee + packagingFee

	updateQuery := `
    UPDATE shopping_cart
    SET item_cost = $2, delivery_fee = $3, platform_fee = $4, small_order_fee = $5, 
        packaging_fee = $6, discounts = $7, number_of_items = $8, subtotal = $9
    WHERE id = $1`
	_, err = s.db.Exec(updateQuery, cart_id, itemCost, deliveryFee, int(platformFee), smallOrderFee, packagingFee, discounts, numberOfItems, subtotal)
	return err
}

/*
	func (s *PostgresStore) CalculateCartTotal(cart_id int) error {
		print("Calculating cart total for cart_id: ", cart_id)
		var itemCost, discounts, numberOfItems, minDeliveryAmount, smallOrderFee, platformFee, packagingFee, deliveryFee int // Changed to float64 to handle decimal values

		var distanceToStore float64

		var orderType string

		// Fetch the order type for the cart
		orderTypeQuery := `SELECT order_type, address.distance_store FROM shopping_cart
	                       JOIN address ON shopping_cart.address_id = address.id
	                       WHERE shopping_cart.id = $1`
		err := s.db.QueryRow(orderTypeQuery, cart_id).Scan(&orderType, &distanceToStore)
		if err != nil {
			return err
		}

		// Calculate total item cost and discounts from cart_item and item_store
		query := `
	    SELECT
	        COALESCE(SUM(CAST(ci.sold_price AS DECIMAL(10, 2)) * ci.quantity), 0),
	        COALESCE(SUM(ci.quantity), 0),
	        COALESCE(SUM((ifin.mrp_price - CAST(ci.sold_price AS DECIMAL(10, 2))) * ci.quantity), 0)
	    FROM cart_item ci
	    JOIN item_financial ifin ON ci.item_id = ifin.item_id
	    WHERE ci.cart_id = $1`

		err = s.db.QueryRow(query, cart_id).Scan(&itemCost, &numberOfItems, &discounts)
		if err != nil {
			return err
		}

		platformFee = int(math.Max(2, math.Round(float64(itemCost)*0.01)))

		if orderType == "delivery" {

			minDeliveryAmountQuery := `SELECT min_delivery_amount FROM delivery_distance
			WHERE $1 > min_distance AND $1 <= max_distance`
			err = s.db.QueryRow(minDeliveryAmountQuery, distanceToStore).Scan(&minDeliveryAmount)
			if err != nil {
				return err
			}

			switch {
			case itemCost >= minDeliveryAmount:
				deliveryFee = 0
				smallOrderFee = 0
			default:
				deliveryFee = 35
				smallOrderFee = 35
			}
		}

		updateQuery := `
	    UPDATE shopping_cart
	    SET item_cost = $2, delivery_fee = $3, platform_fee = $4, small_order_fee = $5,
	        packaging_fee = $6, discounts = $7, number_of_items = $8
	    WHERE id = $1`
		_, err = s.db.Exec(updateQuery, cart_id, itemCost, deliveryFee, platformFee, smallOrderFee, packagingFee, discounts, numberOfItems)
		return err
	}
*/
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

type CartDeliveryDetails struct {
	DeliveryDate string
	StartTime    string
	EndTime      string
}

func (s *PostgresStore) GetCustomerCart(customerId int, cartId int) (*CartDeliveryDetails, error) {
	// SQL query to join shopping_cart and slot tables and retrieve the required information
	query := `
        SELECT sc.delivery_date, sl.start_time, sl.end_time
        FROM shopping_cart sc
        JOIN slot sl ON sc.slot_id = sl.id
        WHERE sc.customer_id = $1 AND sc.id = $2
    `

	// Assuming you have a DB connection set up and available via s.DB or similar
	var details CartDeliveryDetails
	err := s.db.QueryRow(query, customerId, cartId).Scan(&details.DeliveryDate, &details.StartTime, &details.EndTime)
	if err != nil {
		if err == sql.ErrNoRows {
			// Handle the case where there's no such cart for the customer
			return nil, nil // or an appropriate error
		}
		// Handle other potential errors
		return nil, err
	}

	return &details, nil
}

type Slot struct {
	StartTime string
	EndTime   string
	Id        int
	Available bool
}

type CartSlotDetails struct {
	AvailableSlots []Slot
	ChosenSlot     *Slot // Using a pointer so it can be nil if no slot is chosen
	DeliveryDate   string
}

func (s *PostgresStore) GetCartSlots(customerId int, cartId int) (*CartSlotDetails, error) {
	var cartSlots CartSlotDetails
	var distanceStore float64

	newDeliveryDate := time.Now().Add(5*time.Hour+30*time.Minute).AddDate(0, 0, 1)

	// Update the delivery_date in the shopping_cart table
	updateQuery := `UPDATE shopping_cart SET delivery_date = $1 WHERE id = $2 AND customer_id = $3`
	_, err := s.db.Exec(updateQuery, newDeliveryDate, cartId, customerId)
	if err != nil {
		return nil, err
	}

	// Query to fetch the distance_store from the address table using the address_id in the shopping_cart table
	distanceQuery := `SELECT distance_to_store FROM address
					  JOIN shopping_cart ON address.id = shopping_cart.address_id
					  WHERE shopping_cart.id = $1`
	err = s.db.QueryRow(distanceQuery, cartId).Scan(&distanceStore)
	if err != nil {
		return nil, err
	}

	// Query to fetch all slots
	slotsQuery := `SELECT start_time, end_time, slot.id FROM slot`
	rows, err := s.db.Query(slotsQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var startTimeStr, endTimeStr string
		var id int
		if err := rows.Scan(&startTimeStr, &endTimeStr, &id); err != nil {
			return nil, err
		}

		// Determine availability based on distance
		available := true

		cartSlots.AvailableSlots = append(cartSlots.AvailableSlots, Slot{
			StartTime: startTimeStr,
			EndTime:   endTimeStr,
			Id:        id,
			Available: available,
		})
	}

	// Query to fetch the chosen slot
	chosenSlotQuery := `SELECT slot.start_time, slot.end_time, slot.id FROM shopping_cart
                        JOIN slot ON shopping_cart.slot_id = slot.id
                        WHERE shopping_cart.id = $1`
	var chosenStartTimeStr, chosenEndTimeStr string
	var id int
	err = s.db.QueryRow(chosenSlotQuery, cartId).Scan(&chosenStartTimeStr, &chosenEndTimeStr, &id)
	if err == nil {
		// layout := "15:04:05"

		cartSlots.ChosenSlot = &Slot{
			StartTime: chosenStartTimeStr,
			EndTime:   chosenEndTimeStr,
			Id:        id,
			// Assuming the chosen slot respects the distance rule and is thus available
			Available: true,
		}
	} else if err != sql.ErrNoRows {
		return nil, err // return error if it's not the "no rows" error
	}

	layout := "2006-01-02 15:04:05"
	cartSlots.DeliveryDate = newDeliveryDate.Format(layout)

	return &cartSlots, nil
}

func (s *PostgresStore) AssignCartSlot(customerId int, cartId int, slotId int) (*CartSlotDetails, error) {
	// Calculate the delivery date by adding 5:30 hours to the current time and then adding 1 day
	currentTime := time.Now()
	adjustedTime := currentTime.Add(5*time.Hour + 30*time.Minute)
	deliveryDate := adjustedTime.AddDate(0, 0, 1)

	// Update the slot_id and delivery_date in the shopping_cart table in one query
	updateQuery := `
        UPDATE shopping_cart
        SET slot_id = $1, delivery_date = $2
        WHERE id = $3 AND customer_id = $4`

	_, err := s.db.Exec(updateQuery, slotId, deliveryDate, cartId, customerId)
	if err != nil {
		return nil, err
	}

	// Fetch the updated cart slots
	return s.GetCartSlots(customerId, cartId)
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
		createdAt string
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
	val := ValidShoppingCart{false, cartID}
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
	} else if err == sql.ErrNoRows {
		// No active cart exists for the customer
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
	} else {
		return val, err
	}
}
