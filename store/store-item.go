package store

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) CreateItemTable(tx *sql.Tx) error {
	// Define the ENUM type for unit
	unitEnumQuery := `DO $$ BEGIN
                        CREATE TYPE unit_enum AS ENUM ('g', 'mg', 'ml', 'l', 'kg', 'ct', 'pcs');
                    EXCEPTION
                        WHEN duplicate_object THEN null;
                    END $$;`
	_, err := tx.Exec(unitEnumQuery)
	if err != nil {
		return fmt.Errorf("error creating unit_enum type: %w", err)
	}

	createTableQuery := `
    CREATE TABLE IF NOT EXISTS item(
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        brand_id INT REFERENCES brand(id) ON DELETE CASCADE,
        quantity INT NOT NULL,
        barcode VARCHAR(15) UNIQUE,
        unit_of_quantity unit_enum,
        description TEXT DEFAULT 'description',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by INT
    );`

	_, err = tx.Exec(createTableQuery)
	if err != nil {
		return fmt.Errorf("error creating item table: %w", err)
	}

	// Create a unique index on the lowercased name to ensure case-sensitive uniqueness
	createNameIndexQuery := `CREATE UNIQUE INDEX IF NOT EXISTS item_name_unique ON item (LOWER(name));`
	_, err = tx.Exec(createNameIndexQuery)
	if err != nil {
		return fmt.Errorf("error creating unique index for name: %w", err)
	}

	// Create partial index for barcode, ensuring it remains unique where it is not null
	createBarcodeIndexQuery := `CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_nonempty_barcode ON item(barcode) WHERE barcode IS NOT NULL;`
	_, err = tx.Exec(createBarcodeIndexQuery)
	if err != nil {
		return fmt.Errorf("error creating partial index for barcode: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateItemTaxTable(tx *sql.Tx) error {
	// SQL query to create the 'ItemTax' table with a default value for 'hsn_code'
	createItemTaxTableQuery := `
    CREATE TABLE IF NOT EXISTS ItemTax (
        item_id INT NOT NULL,
        tax_id INT NOT NULL,
        hsn_code TEXT NOT NULL DEFAULT '',
        PRIMARY KEY (item_id, tax_id),
        FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE,
        FOREIGN KEY (tax_id) REFERENCES tax(id) ON DELETE CASCADE
    );`

	// Execute the query using the provided transaction
	_, err := tx.Exec(createItemTaxTableQuery)
	if err != nil {
		return fmt.Errorf("error creating ItemTax table: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateItemCategoryTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists item_category(
		item_id INT REFERENCES item(id) ON DELETE CASCADE,
		category_id INT REFERENCES category(id) ON DELETE CASCADE,
		PRIMARY KEY(item_id, category_id),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item_category table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItemImageTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateItemTable")

	query := `
		create table if not exists item_image(
			id SERIAL PRIMARY KEY,
			item_id INT REFERENCES item(id) ON DELETE CASCADE,
			image_url TEXT NOT NULL,
			order_position INT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			created_by INT,
			UNIQUE (item_id, order_position)  
		)`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item_image table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItemStoreTable(tx *sql.Tx) error {
	query := `
        CREATE TABLE IF NOT EXISTS item_store (
            id SERIAL PRIMARY KEY,
            item_id INT REFERENCES item(id) ON DELETE CASCADE,
            store_price INT NOT NULL,
            discount INT NOT NULL,
            store_id INT REFERENCES store(id) ON DELETE CASCADE,
            stock_quantity INT NOT NULL,
            locked_quantity INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by INT,
            UNIQUE (item_id, store_id) 
        )
    `

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item_store table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItem(p *types.Item) (*types.Item, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}

	// Derive store_id using store name
	var storeID int
	storeIDQuery := `SELECT id FROM store WHERE name = $1`
	err = tx.QueryRow(storeIDQuery, p.Store).Scan(&storeID)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error deriving store id: %w", err)
	}

	// Derive brand_id using brand name
	var brandID int
	brandIDQuery := `SELECT id FROM brand WHERE name = $1`
	err = tx.QueryRow(brandIDQuery, p.Brand).Scan(&brandID)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error deriving brand id: %w", err)
	}

	// Derive category_id using category name
	var categoryIDs []int
	categoryNames := p.Category

	categoryIDQuery := `SELECT id FROM category WHERE name = ANY($1)`
	rows, err := tx.Query(categoryIDQuery, pq.Array(categoryNames))
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error deriving category ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var id int
		err = rows.Scan(&id)
		if err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("error scanning category id: %w", err)
		}
		categoryIDs = append(categoryIDs, id)
	}

	if len(categoryIDs) != len(categoryNames) {
		tx.Rollback()
		return nil, fmt.Errorf("some category names did not have corresponding IDs")
	}

	// Calculate store price
	storePrice := p.MRP_Price - p.Discount

	// Set description to name if not provided
	description := p.Name
	if p.Description != "" {
		description = p.Description
	}

	newItem := &types.Item{
		Name:             p.Name,
		MRP_Price:        p.MRP_Price,
		Discount:         p.Discount,
		Store_Price:      storePrice,
		Description:      description,
		Store:            p.Store,
		Category:         p.Category,
		Brand:            p.Brand,
		Stock_Quantity:   p.Stock_Quantity,
		Quantity:         p.Quantity,
		Unit_Of_Quantity: p.Unit_Of_Quantity,
		Image:            p.Image,
		Created_By:       1, // Assuming a default user ID for creation
	}

	// Insert into item table
	query := `INSERT INTO item (name, brand_id, description, quantity, unit_of_quantity, created_by) 
              VALUES ($1, $2, $3, $4, $5, $6) 
              RETURNING id, created_at`
	err = tx.QueryRow(query, newItem.Name, brandID, newItem.Description, newItem.Quantity, newItem.Unit_Of_Quantity, newItem.Created_By).Scan(&newItem.ID, &newItem.Created_At)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item: %w", err)
	}

	// Insert into item_store table
	query = `INSERT INTO item_store (item_id, mrp_price, store_price, discount, store_id, stock_quantity, locked_quantity, created_by) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`
	_, err = tx.Exec(query, newItem.ID, newItem.MRP_Price, storePrice, newItem.Discount, storeID, newItem.Stock_Quantity, 0, newItem.Created_By)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_store: %w", err)
	}

	// Insert into item_category table
	query = `INSERT INTO item_category (item_id, category_id, created_by) VALUES ($1, $2, $3)`

	for _, categoryID := range categoryIDs {
		_, err = tx.Exec(query, newItem.ID, categoryID, newItem.Created_By)
		if err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("error inserting into item_category: %w", err)
		}
	}

	// Insert into item_image table
	query = `INSERT INTO item_image (item_id, image_url, order_position, created_by) 
             VALUES ($1, $2, $3, $4)`
	_, err = tx.Exec(query, newItem.ID, newItem.Image, 1, newItem.Created_By) // Default order_position set to 1
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_image: %w", err)
	}

	// Commit transaction
	err = tx.Commit()
	if err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return newItem, nil
}

func (s *PostgresStore) GetItems() ([]*types.Get_Item, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback()

	query := `
    WITH category_agg AS (
		SELECT 
			ic.item_id,
			array_agg(COALESCE(c.name, 'No Category')) AS categories
		FROM item_category ic
		LEFT JOIN category c ON ic.category_id = c.id
		GROUP BY ic.item_id
	), image_agg AS (
		SELECT 
			ii.item_id,
			array_agg(ii.image_url) AS images
		FROM item_image ii
		GROUP BY ii.item_id
	)
	SELECT 
		i.id, i.name, i.description, i.quantity, i.unit_of_quantity, b.name, 
		istore.mrp_price, istore.discount, istore.store_price, s.name, 
		istore.stock_quantity, istore.locked_quantity,
		COALESCE(ca.categories, ARRAY['No Category']::text[]) as categories,
		COALESCE(ia.images, ARRAY[]::text[]) as images
	FROM item i
	LEFT JOIN brand b ON i.brand_id = b.id
	LEFT JOIN item_store istore ON i.id = istore.item_id
	LEFT JOIN store s ON istore.store_id = s.id
	LEFT JOIN category_agg ca ON i.id = ca.item_id
	LEFT JOIN image_agg ia ON i.id = ia.item_id
	GROUP BY i.id, i.name, b.name, istore.mrp_price, istore.discount, 
			 istore.store_price, s.name, istore.stock_quantity, 
			 istore.locked_quantity, ca.categories, ia.images
	ORDER BY i.id
	
    `

	rows, err := tx.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error querying items: %w", err)
	}
	defer rows.Close()

	var items []*types.Get_Item

	for rows.Next() {
		item := &types.Get_Item{}
		var store string
		var categories pq.StringArray
		var images pq.StringArray

		err := rows.Scan(
			&item.ID,
			&item.Name,
			&item.Description,
			&item.Quantity,
			&item.Unit_Of_Quantity,
			&item.Brand,
			&item.MRP_Price,
			&item.Discount,
			&item.Store_Price,
			&store,
			&item.Stock_Quantity,
			&item.Locked_Quantity,
			&categories,
			&images,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning row into item: %w", err)
		}

		// Convert pq.StringArray to []string
		item.Categories = make([]string, len(categories))
		copy(item.Categories, categories)

		item.Images = make([]string, len(images))
		copy(item.Images, images)

		item.Stores = append(item.Stores, store)

		items = append(items, item)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating through rows: %w", err)
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return items, nil
}

func (s *PostgresStore) Get_Items_By_CategoryID_And_StoreID(category_id int, store_id int) ([]*types.Get_Items_By_CategoryID_And_StoreID, error) {
	fmt.Println("Entered Get_Items_By_CategoryID_And_StoreID")

	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}

	query := `
    SELECT 
        i.id, 
        i.name, 
        i.quantity,
        i.unit_of_quantity,
        b.name AS brand_name,
        ifin.mrp_price, 
        istore.discount,  
        (ifin.mrp_price - istore.discount) AS store_price, 
        s.name AS store_name,
        c.name AS category_name,
        istore.stock_quantity,
        istore.locked_quantity,
        array_agg(COALESCE(ii.image_url, 'default_image')) FILTER (WHERE ii.image_url IS NOT NULL) AS images, 
        i.created_at,
        COALESCE(i.created_by, 0) AS created_by
    FROM item i
    JOIN item_category ic ON i.id = ic.item_id
    JOIN item_store istore ON i.id = istore.item_id
    JOIN item_financial ifin ON i.id = ifin.item_id 
    JOIN brand b ON i.brand_id = b.id
    JOIN store s ON istore.store_id = s.id
    JOIN category c ON ic.category_id = c.id
    LEFT JOIN item_image ii ON i.id = ii.item_id
    WHERE ic.category_id = $1 AND istore.store_id = $2
    GROUP BY i.id, b.name, s.name, c.name, ifin.mrp_price, istore.discount, istore.stock_quantity, istore.locked_quantity
    `

	rows, err := tx.Query(query, category_id, store_id)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error querying items by category and store: %w", err)
	}
	defer rows.Close()

	items := []*types.Get_Items_By_CategoryID_And_StoreID{}
	for rows.Next() {
		item := &types.Get_Items_By_CategoryID_And_StoreID{}
		var images []string
		err := rows.Scan(
			&item.ID,
			&item.Name,
			&item.Quantity,
			&item.Unit_Of_Quantity,
			&item.Brand,
			&item.MRP_Price,
			&item.Discount,
			&item.Store_Price,
			&item.Store,
			&item.Category,
			&item.Stock_Quantity,
			&item.Locked_Quantity,
			pq.Array(&images),
			&item.Created_At,
			&item.Created_By,
		)
		if err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("error scanning row: %w", err)
		}
		item.Images = images
		items = append(items, item)
	}

	err = tx.Commit()
	if err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return items, nil
}

func (s *PostgresStore) Get_Item_By_ID(id int) (*types.Get_Item_Barcode, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback()

	item := &types.Get_Item_Barcode{}

	// Get basic item data, brand name, and description
	query := `SELECT i.id, i.name, i.quantity, i.unit_of_quantity, b.name, i.description, i.created_at, i.created_by, i.barcode FROM item i
              LEFT JOIN brand b ON i.brand_id = b.id
              WHERE i.id = $1`
	row := tx.QueryRow(query, id)
	var barcode sql.NullString

	if err := row.Scan(&item.ID, &item.Name, &item.Quantity, &item.Unit_Of_Quantity, &item.Brand, &item.Description, &item.Created_At, &item.Created_By, &barcode); err != nil {
		// Handle error
		return nil, err
	}

	// Check if barcode is not NULL and assign the value to item.Barcode
	if barcode.Valid {
		item.Barcode = barcode.String
	} else {
		// Handle or assign a default value if barcode is NULL
		item.Barcode = ""
	}

	// Get categories
	query = `SELECT c.name FROM item_category ic
             JOIN category c ON ic.category_id = c.id
             WHERE ic.item_id = $1`
	rows, err := tx.Query(query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var categoryName string
		if err := rows.Scan(&categoryName); err != nil {
			return nil, err
		}
		item.Categories = append(item.Categories, categoryName)
	}

	// Get images
	query = `SELECT image_url FROM item_image WHERE item_id = $1 ORDER BY order_position`
	rows, err = tx.Query(query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var imageUrl string
		if err := rows.Scan(&imageUrl); err != nil {
			return nil, err
		}
		item.Images = append(item.Images, imageUrl)
	}

	// Get store-related details. Assuming an item can be in multiple stores.
	query = `SELECT s.name, istore.mrp_price, istore.discount, istore.store_price, istore.stock_quantity, istore.locked_quantity 
             FROM item_store istore
             JOIN store s ON istore.store_id = s.id
             WHERE istore.item_id = $1`
	rows, err = tx.Query(query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var storeName string
		var price, discount, storePrice float64
		var stockQuantity, lockedQuantity int

		if err := rows.Scan(&storeName, &price, &discount, &storePrice, &stockQuantity, &lockedQuantity); err != nil {
			return nil, err
		}
		item.Stores = append(item.Stores, storeName)
		item.MRP_Price = price
		item.Discount = discount
		item.Store_Price = storePrice
		item.Stock_Quantity = stockQuantity
		item.Locked_Quantity = lockedQuantity
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return item, nil
}

func (s *PostgresStore) Update_Item(item *types.Update_Item) (*types.Update_Item, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}

	// Update item table
	query := `UPDATE item SET name = $1, description = $2 WHERE id = $3`
	if _, err := tx.Exec(query, item.Name, item.Description, item.ID); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item: %w", err)
	}

	// Update item_store table
	query = `UPDATE item_store SET mrp_price = $1, discount = $2, stock_quantity = $3 
             WHERE item_id = $4 AND store_id = 
             (SELECT id FROM store WHERE name = $5 LIMIT 1)`
	if _, err := tx.Exec(query, item.MRP_Price, item.Discount, item.Stock_Quantity, item.ID, item.Store); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item_store: %w", err)
	}

	// Update item_image table. We use the Order_Position to determine which image to update
	query = `UPDATE item_image SET image_url = $1 WHERE item_id = $2 AND order_position = $3`
	if _, err := tx.Exec(query, item.Image, item.ID, item.Order_Position); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item_image: %w", err)
	}

	// Update item_category table. We link the item to the category by name
	query = `UPDATE item_category SET category_id = 
             (SELECT id FROM category WHERE name = $1 LIMIT 1) 
             WHERE item_id = $2`
	if _, err := tx.Exec(query, item.Category, item.ID); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item_category: %w", err)
	}

	err = tx.Commit()
	if err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return item, nil
}

func (s *PostgresStore) Delete_Item(item_id int) error {
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %w", err)
	}

	// Delete from item_store table
	_, err = tx.Exec("DELETE FROM item_store WHERE item_id = $1", item_id)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error deleting from item_store: %w", err)
	}

	// Delete from item_category table
	_, err = tx.Exec("DELETE FROM item_category WHERE item_id = $1", item_id)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error deleting from item_category: %w", err)
	}

	// Delete from item_image table
	_, err = tx.Exec("DELETE FROM item_image WHERE item_id = $1", item_id)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error deleting from item_image: %w", err)
	}

	// Delete from item table
	_, err = tx.Exec("DELETE FROM item WHERE id = $1", item_id)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error deleting from item: %w", err)
	}

	// Commit transaction
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("error committing transaction: %w", err)
	}

	return nil
}

func (s *PostgresStore) AddStockToItem() ([]*types.Get_Item, error) {
	// Start a new transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback() // This will rollback the transaction if it hasn't been committed at the end of the function

	// Increment stock_quantity by 10 for all items in item_store table
	_, err = tx.Exec(`UPDATE item_store SET stock_quantity = stock_quantity + 10`)
	if err != nil {
		return nil, fmt.Errorf("error updating stock quantities: %w", err)
	}

	// Query to fetch updated values
	query := `
        SELECT
            i.id, i.name, 
            istore.mrp_price, istore.discount, istore.store_price, 
            i.description, 
            ARRAY_AGG(s.name) AS stores,
            ARRAY_AGG(c.name) AS categories,
            istore.stock_quantity, istore.locked_quantity,
            ARRAY_AGG(img.image_url) AS images,
            b.name AS brand, 
            i.quantity, i.unit_of_quantity, 
            i.created_at, i.created_by
        FROM item i
        LEFT JOIN item_store istore ON i.id = istore.item_id
        LEFT JOIN store s ON istore.store_id = s.id
        LEFT JOIN item_category ic ON i.id = ic.item_id
        LEFT JOIN category c ON ic.category_id = c.id
        LEFT JOIN item_image img ON i.id = img.item_id
        LEFT JOIN brand b ON i.brand_id = b.id
        GROUP BY i.id, istore.mrp_price, istore.discount, istore.store_price, istore.stock_quantity, istore.locked_quantity, b.name
    `

	rows, err := tx.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error fetching updated items: %w", err)
	}
	defer rows.Close()

	var items []*types.Get_Item

	for rows.Next() {
		item := &types.Get_Item{}
		var stores pq.StringArray
		var categories pq.StringArray
		var images pq.StringArray
		err = rows.Scan(&item.ID, &item.Name, &item.MRP_Price, &item.Discount, &item.Store_Price, &item.Description, &stores, &categories, &item.Stock_Quantity, &item.Locked_Quantity, &images, &item.Brand, &item.Quantity, &item.Unit_Of_Quantity, &item.Created_At, &item.Created_By)
		if err != nil {
			return nil, fmt.Errorf("error scanning row into item: %w", err)
		}

		item.Stores = stores
		item.Categories = categories
		item.Images = images

		items = append(items, item)
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return items, nil
}

type StockUpdateInfo struct {
	ItemID        int    `json:"item_id"`
	ItemName      string `json:"item_name"`
	AddedStock    int    `json:"added_stock"`
	StockQuantity int    `json:"stock_quantity"`
	StoreId       int    `json:"store_id"`
}

func (s *PostgresStore) AddStockToItemByStore(item_id int, store_id int, stock int) (StockUpdateInfo, error) {
	// Initialize an empty StockUpdateInfo struct
	print("Enter AddStockToItemByStore")
	stockInfo := StockUpdateInfo{}

	// Start a new transaction
	tx, err := s.db.Begin()
	if err != nil {
		return stockInfo, fmt.Errorf("error starting transaction: %w", err)
	}

	// Prepare the SQL query for updating stock
	updateQuery := `UPDATE item_store SET stock_quantity = stock_quantity + $1 WHERE item_id = $2 AND store_id = $3`

	// Execute the update query with the provided stock, item_id, and store_id
	_, err = tx.Exec(updateQuery, stock, item_id, store_id)
	if err != nil {
		// If there is an error, rollback the transaction
		tx.Rollback()
		return stockInfo, fmt.Errorf("error updating stock for item: %w", err)
	}

	// Prepare the SQL query to retrieve the updated information
	selectQuery := `SELECT i.name, istore.item_id, istore.stock_quantity FROM item i INNER JOIN item_store istore ON i.id = istore.item_id WHERE istore.item_id = $1 AND istore.store_id = $2`

	// Query the item name and item id
	row := tx.QueryRow(selectQuery, item_id, store_id)
	err = row.Scan(&stockInfo.ItemName, &stockInfo.ItemID, &stockInfo.StockQuantity)
	if err != nil {
		// If there is an error, rollback the transaction
		tx.Rollback()
		return stockInfo, fmt.Errorf("error fetching updated item information: %w", err)
	}

	// Commit the transaction if no errors
	if err = tx.Commit(); err != nil {
		return stockInfo, fmt.Errorf("error committing transaction: %w", err)
	}

	// Add the stock to the struct since it's not part of the SELECT query
	stockInfo.AddedStock = stock
	stockInfo.StoreId = store_id

	return stockInfo, nil
}

type ItemAdd struct {
	ID            int      `json:"id"`
	Name          string   `json:"name"`
	Brand         string   `json:"brand"`
	Quantity      int      `json:"quantity"`
	Barcode       string   `json:"barcode"`
	Unit          string   `json:"unit"`
	StoreID       int      `json:"store_id"`
	StockQuantity int      `json:"stock_quantity"`
	ImageURLs     []string `json:"image_urls"`
}

func (s *PostgresStore) GetItemAdd(barcode string, storeId int) (*ItemAdd, error) {
	var item ItemAdd

	// SQL query to join item, item_store, and item_image tables
	query := `
        SELECT i.id, i.name, b.name, i.quantity, i.barcode, i.unit_of_quantity, 
               istore.store_id, istore.stock_quantity, array_agg(ii.image_url)
        FROM item i
        JOIN item_store istore ON i.id = istore.item_id
        JOIN item_image ii ON i.id = ii.item_id
        JOIN brand b ON i.brand_id = b.id
        WHERE i.barcode = $1 AND istore.store_id = $2
        GROUP BY i.id, b.name, istore.store_id, istore.stock_quantity
    `

	row := s.db.QueryRow(query, barcode, storeId)
	var imageURLs []string
	err := row.Scan(&item.ID, &item.Name, &item.Brand, &item.Quantity, &item.Barcode,
		&item.Unit, &item.StoreID, &item.StockQuantity, pq.Array(&imageURLs))
	if err != nil {
		if err == sql.ErrNoRows {
			println("No Item Found")
			return nil, fmt.Errorf("no item found with barcode %s at store %d", barcode, storeId)
		}
		println("Error ", err)

		return nil, fmt.Errorf("error querying item: %w", err)
	}

	item.ImageURLs = imageURLs
	return &item, nil
}

func (s *PostgresStore) AddBarcodeToItem(barcode string, item_id int) (bool, error) {
	// Prepare the SQL query to update the item

	query := `UPDATE item SET barcode = $1 WHERE id = $2`

	// Execute the query with the provided barcode and item_id
	result, err := s.db.Exec(query, barcode, item_id)
	if err != nil {
		// If there is an error executing the query, return false and the error
		return false, fmt.Errorf("error updating item barcode: %w", err)
	}

	// Check how many rows were affected
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		// If there is an error checking the rows affected, return false and the error
		return false, fmt.Errorf("error getting rows affected: %w", err)
	}

	// If no rows were affected, return false and no error
	if rowsAffected == 0 {
		return false, nil
	}

	// If the update was successful, return true and no error
	return true, nil
}

func (s *PostgresStore) AddStockUpdateItem(add_stock int, item_id int) (bool, error) {
	// Prepare the SQL query to update the item
	query := `UPDATE item_store SET stock_quantity = stock_quantity + $1 WHERE item_id = $2`

	result, err := s.db.Exec(query, add_stock, item_id)
	if err != nil {
		return false, fmt.Errorf("error updating item add stock: %w", err)
	}

	// Check how many rows were affected
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		// If there is an error checking the rows affected, return false and the error
		return false, fmt.Errorf("error getting rows affected: %w", err)
	}

	// If no rows were affected, return false and no error
	if rowsAffected == 0 {
		return false, nil
	}

	// If the update was successful, return true and no error
	return true, nil
}

// Define a struct to hold the item data
type ItemData struct {
	ID             int      `json:"id"`
	Name           string   `json:"name"`
	MRPPrice       int      `json:"mrp_price"`
	UnitOfQuantity string   `json:"unit_of_quantity"`
	Quantity       int      `json:"quantity"`
	Images         []string `json:"images"`
}

type ItemDataQuantity struct {
	ID             int      `json:"id"`
	Name           string   `json:"name"`
	MRPPrice       int      `json:"mrp_price"`
	UnitOfQuantity string   `json:"unit_of_quantity"`
	Quantity       int      `json:"quantity"`
	StockQuantity  int      `json:"stock_quantity"`
	Images         []string `json:"images"`
}

func (s *PostgresStore) GetItemFromBarcode(barcode string) (*ItemData, error) {
	// SQL query to get item details and MRP price
	itemQuery := `
		SELECT i.id, i.name, istore.mrp_price, i.unit_of_quantity, i.quantity
		FROM item i
		INNER JOIN item_store istore ON i.id = istore.item_id
		WHERE i.barcode = $1
	`

	// Query the item table
	var itemData ItemData
	err := s.db.QueryRow(itemQuery, barcode).Scan(&itemData.ID, &itemData.Name, &itemData.MRPPrice, &itemData.UnitOfQuantity, &itemData.Quantity)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no item found with barcode %s", barcode)
		}
		return nil, fmt.Errorf("error querying item table: %w", err)
	}

	// SQL query to get item image URLs
	imageQuery := `
		SELECT image_url
		FROM item_image
		WHERE item_id = (SELECT id FROM item WHERE barcode = $1)
		ORDER BY order_position
	`

	// Query the item_image table
	rows, err := s.db.Query(imageQuery, barcode)
	if err != nil {
		return nil, fmt.Errorf("error querying item_image table: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var imageURL string
		if err := rows.Scan(&imageURL); err != nil {
			return nil, fmt.Errorf("error scanning item_image row: %w", err)
		}
		itemData.Images = append(itemData.Images, imageURL)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error in item_image rows: %w", err)
	}

	return &itemData, nil
}

func (s *PostgresStore) GetItemFromBarcodeInOrder(barcode string, salesOrderId int, packerPhone string) (*ItemDataQuantity, error) {
	itemQuery := `
    SELECT i.id, i.name, istore.mrp_price, i.unit_of_quantity, i.quantity, ci.quantity, array_agg(ii.image_url) 
    FROM sales_order so
    JOIN cart_item ci ON so.cart_id = ci.cart_id
    JOIN item i ON ci.item_id = i.id
    JOIN item_store istore ON i.id = istore.item_id
    LEFT JOIN item_image ii ON i.id = ii.item_id
    JOIN packer p ON so.packer_id = p.id
    WHERE so.id = $1 AND p.phone = $2 AND i.barcode = $3
    GROUP BY i.id, i.name, istore.mrp_price, i.unit_of_quantity, i.quantity, ci.quantity	
    `

	var itemData ItemDataQuantity
	var images pq.StringArray
	err := s.db.QueryRow(itemQuery, salesOrderId, packerPhone, barcode).Scan(&itemData.ID, &itemData.Name, &itemData.MRPPrice, &itemData.UnitOfQuantity, &itemData.Quantity, &itemData.StockQuantity, &images)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no item found with barcode %s in sales order %d for packer with phone %s", barcode, salesOrderId, packerPhone)
		}
		return nil, fmt.Errorf("error querying for item: %w", err)
	}

	itemData.Images = images

	return &itemData, nil
}

func (s *PostgresStore) CreateItemAddQuick(params types.ItemAddQuick) (ItemAddQuickResponse, error) {
	// Start a transaction
	response := ItemAddQuickResponse{Success: false} // Initialize with false success

	tx, err := s.db.Begin()
	if err != nil {
		return response, fmt.Errorf("error starting transaction: %w", err)
	}

	// Check if brand exists, if not create it
	var brandId int
	brandQuery := `SELECT id FROM brand WHERE name = $1`
	err = tx.QueryRow(brandQuery, params.BrandName).Scan(&brandId)
	if err == sql.ErrNoRows {
		// Brand does not exist, create it
		insertBrandQuery := `INSERT INTO brand (name) VALUES ($1) RETURNING id`
		err = tx.QueryRow(insertBrandQuery, params.BrandName).Scan(&brandId)
		if err != nil {
			tx.Rollback()
			return response, fmt.Errorf("error inserting new brand: %w", err)
		}
	} else if err != nil {
		tx.Rollback()
		return response, fmt.Errorf("error querying brand: %w", err)
	}

	// Insert into item table
	itemQuery := `INSERT INTO item (name, brand_id, quantity, barcode, unit_of_quantity, description, created_by) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`
	var itemId int
	err = tx.QueryRow(itemQuery, params.Name, brandId, params.Quantity, params.Barcode, params.Unit, params.Description, params.CreatedBy).Scan(&itemId)
	if err != nil {
		tx.Rollback()
		return response, fmt.Errorf("error inserting item: %w", err)
	}

	// Insert into item_category table
	categoryQuery := `INSERT INTO item_category (item_id, category_id, created_by) VALUES ($1, $2, $3)`
	_, err = tx.Exec(categoryQuery, itemId, params.CategoryId, params.CreatedBy)
	if err != nil {
		tx.Rollback()
		return response, fmt.Errorf("error inserting item category: %w", err)
	}

	// Insert into item_image table with empty image_url
	imageQuery := `INSERT INTO item_image (item_id, image_url, order_position, created_by) VALUES ($1, '', 1, $2)`
	_, err = tx.Exec(imageQuery, itemId, params.CreatedBy)
	if err != nil {
		tx.Rollback()
		return response, fmt.Errorf("error inserting item image: %w", err)
	}

	// Insert into item_store table
	storeQuery := `INSERT INTO item_store (item_id, mrp_price, store_price, discount, store_id, stock_quantity, created_by) VALUES ($1, $2, $3, $4, $5, $6, $7)`
	_, err = tx.Exec(storeQuery, itemId, params.MrpPrice, params.StorePrice, params.Discount, params.StoreId, params.StockQuantity, params.CreatedBy)
	if err != nil {
		tx.Rollback()
		return response, fmt.Errorf("error inserting item store: %w", err)
	}

	// Commit the transaction
	if commitErr := tx.Commit(); commitErr != nil {
		return response, fmt.Errorf("error committing transaction: %w", commitErr)
	}

	response.Success = true // Set success to true as the transaction is committed successfully
	return response, nil
}

type ItemAddQuickResponse struct {
	Success bool `json:"success"`
}

type ManagerItem struct {
	ID             int       `json:"id"`
	Name           string    `json:"name"`
	BrandID        int       `json:"brand_id"`
	BrandName      string    `json:"brand_name"` // New field for the brand name
	Quantity       int       `json:"quantity"`
	Barcode        *string   `json:"barcode"`
	UnitOfQuantity string    `json:"unit_of_quantity"`
	Description    string    `json:"description"`
	CreatedAt      time.Time `json:"created_at"`
	CreatedBy      int       `json:"created_by"`
	CategoryIDs    []int     `json:"category_ids"`
	CategoryNames  []string  `json:"category_names"`
	ImageURLs      []string  `json:"image_urls"`
}

func (s *PostgresStore) GetManagerItems() ([]ManagerItem, error) {
	items := []ManagerItem{}

	query := `
SELECT
    i.id,
    i.name,
    i.brand_id,
    b.name as brand_name,  -- Select the brand name from the brand table
    i.quantity,
    COALESCE(i.barcode, '') as barcode,
    i.unit_of_quantity,
    i.description,
    i.created_at,
    COALESCE(i.created_by, 0) as created_by,
    COALESCE(ARRAY_AGG(DISTINCT ic.category_id) FILTER (WHERE ic.category_id IS NOT NULL), ARRAY[]::INT[]) AS category_ids,
    COALESCE(ARRAY_AGG(DISTINCT c.name) FILTER (WHERE ic.category_id IS NOT NULL), ARRAY[]::TEXT[]) AS category_names,
    COALESCE(ARRAY_AGG(DISTINCT ii.image_url) FILTER (WHERE ii.image_url IS NOT NULL), ARRAY[]::TEXT[]) AS image_urls
FROM
    item i
LEFT JOIN brand b ON i.brand_id = b.id  -- Join with the brand table
LEFT JOIN item_category ic ON i.id = ic.item_id
LEFT JOIN category c ON ic.category_id = c.id
LEFT JOIN item_image ii ON i.id = ii.item_id
GROUP BY
    i.id, b.name  -- Group by brand name as well
`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error executing query for manager items: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var item ManagerItem
		var barcode sql.NullString
		var createdBy sql.NullInt64
		var categoryIDs []sql.NullInt64
		var categoryNames []sql.NullString
		var imageUrls []sql.NullString

		err = rows.Scan(&item.ID, &item.Name, &item.BrandID, &item.BrandName, &item.Quantity, &barcode, &item.UnitOfQuantity, &item.Description, &item.CreatedAt, &createdBy, pq.Array(&categoryIDs), pq.Array(&categoryNames), pq.Array(&imageUrls))
		if err != nil {
			return nil, fmt.Errorf("error scanning row into ManagerItem: %w", err)
		}

		if barcode.Valid {
			item.Barcode = &barcode.String
		}
		item.CreatedBy = int(createdBy.Int64) // Direct assignment as we're using COALESCE in SQL

		for _, cid := range categoryIDs {
			if cid.Valid {
				item.CategoryIDs = append(item.CategoryIDs, int(cid.Int64))
			}
		}

		for _, cname := range categoryNames {
			if cname.Valid {
				item.CategoryNames = append(item.CategoryNames, cname.String)
			}
		}

		for _, url := range imageUrls {
			if url.Valid {
				item.ImageURLs = append(item.ImageURLs, url.String)
			}
		}

		items = append(items, item)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over rows: %w", err)
	}

	return items, nil
}

func (s *PostgresStore) GetManagerItem(id int) (*ManagerItem, error) {
	var item ManagerItem
	var barcode sql.NullString
	var createdBy sql.NullInt64
	var categoryIDs []sql.NullInt64
	var categoryNames []sql.NullString
	var imageUrls []sql.NullString

	query := `
SELECT
    i.id,
    i.name,
    i.brand_id,
    b.name as brand_name,
    i.quantity,
    COALESCE(i.barcode, '') as barcode,
    i.unit_of_quantity,
    i.description,
    i.created_at,
    COALESCE(i.created_by, 0) as created_by,
    COALESCE(ARRAY_AGG(DISTINCT ic.category_id) FILTER (WHERE ic.category_id IS NOT NULL), ARRAY[]::INT[]) AS category_ids,
    COALESCE(ARRAY_AGG(DISTINCT c.name) FILTER (WHERE ic.category_id IS NOT NULL), ARRAY[]::TEXT[]) AS category_names,
    COALESCE(ARRAY_AGG(DISTINCT ii.image_url) FILTER (WHERE ii.image_url IS NOT NULL), ARRAY[]::TEXT[]) AS image_urls
FROM
    item i
LEFT JOIN brand b ON i.brand_id = b.id
LEFT JOIN item_category ic ON i.id = ic.item_id
LEFT JOIN category c ON ic.category_id = c.id
LEFT JOIN item_image ii ON i.id = ii.item_id
WHERE
    i.id = $1
GROUP BY
    i.id, b.name
`

	row := s.db.QueryRow(query, id)
	err := row.Scan(&item.ID, &item.Name, &item.BrandID, &item.BrandName, &item.Quantity, &barcode, &item.UnitOfQuantity, &item.Description, &item.CreatedAt, &createdBy, pq.Array(&categoryIDs), pq.Array(&categoryNames), pq.Array(&imageUrls))
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no ManagerItem found with ID %d", id)
		}
		return nil, fmt.Errorf("error scanning row into ManagerItem: %w", err)
	}

	// Handling nullable fields and converting them to their Go counterparts
	if barcode.Valid {
		item.Barcode = &barcode.String // use the address of barcode.String
	}
	if createdBy.Valid {
		createdByValue := int(createdBy.Int64) // convert int64 to int
		item.CreatedBy = createdByValue
	}

	for _, cid := range categoryIDs {
		if cid.Valid {
			item.CategoryIDs = append(item.CategoryIDs, int(cid.Int64))
		}
	}

	for _, cname := range categoryNames {
		if cname.Valid {
			item.CategoryNames = append(item.CategoryNames, cname.String)
		}
	}

	for _, url := range imageUrls {
		if url.Valid {
			item.ImageURLs = append(item.ImageURLs, url.String)
		}
	}

	return &item, nil
}

func (s *PostgresStore) EditItem(item *types.ItemEdit) (*types.ItemEdit, error) {
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Update the item in the 'item' table
	updateItemQuery := `
        UPDATE item
        SET name = $2, brand_id = $3, quantity = $4, unit_of_quantity = $5, description = $6
        WHERE id = $1;
    `
	_, err = tx.Exec(updateItemQuery, item.ID, item.Name, item.BrandID, item.Size, item.Unit, item.Description)
	if err != nil {
		return nil, fmt.Errorf("error updating item: %w", err)
	}

	// Fetch category IDs from the category names
	var categoryIDs []int
	fetchCategoriesQuery := `SELECT id FROM category WHERE name = ANY($1);`
	rows, err := tx.Query(fetchCategoriesQuery, pq.Array(item.Categories))
	if err != nil {
		return nil, fmt.Errorf("error fetching category IDs: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var id int
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("error scanning category ID: %w", err)
		}
		categoryIDs = append(categoryIDs, id)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating category IDs: %w", err)
	}

	// Delete obsolete item-category associations
	deleteObsoleteQuery := `
        DELETE FROM item_category
        WHERE item_id = $1 AND category_id != ALL($2);
    `
	_, err = tx.Exec(deleteObsoleteQuery, item.ID, pq.Array(categoryIDs))
	if err != nil {
		return nil, fmt.Errorf("error deleting obsolete item-category associations: %w", err)
	}

	// Insert new category associations, ignoring existing ones to avoid duplication errors
	// Use a CTE to unnest the array and then perform the insert
	insertNewQuery := `
        WITH unnested AS (
            SELECT unnest($2::int[]) AS category_id
        )
        INSERT INTO item_category (item_id, category_id)
        SELECT $1, unnested.category_id
        FROM unnested
        WHERE NOT EXISTS (
            SELECT 1 FROM item_category WHERE item_id = $1 AND category_id = unnested.category_id
        )
        ON CONFLICT (item_id, category_id) DO NOTHING;
    `
	_, err = tx.Exec(insertNewQuery, item.ID, pq.Array(categoryIDs))
	if err != nil {
		return nil, fmt.Errorf("error inserting new item-category associations: %w", err)
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return item, nil
}

func (s *PostgresStore) AddItemFinancials(item *types.ItemFinancials) (*types.ItemFinancials, error) {
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p) // re-throw panic after Rollback
		} else if err != nil {
			tx.Rollback() // err is non-nil; don't change it
		} else {
			err = tx.Commit() // if Commit returns error update err with commit err
		}
	}()

	// Calculate GST amounts for both buy price and MRP
	gstOnBuy := item.BuyPrice * item.GSTRate / 100
	gstOnMRP := item.MRPPrice * item.GSTRate / 100

	// Calculate prices without GST
	buyPriceWithoutGST := item.BuyPrice - gstOnBuy
	mrpPriceWithoutGST := item.MRPPrice - gstOnMRP

	// Prepare the insert statement for the item_financial table
	insertItemFinancialQuery := `
        INSERT INTO item_financial (item_id, buy_price, gst_on_buy, buy_price_without_gst, mrp_price, gst_on_mrp, mrp_price_without_gst, margin, current_scheme_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    `

	// Execute the insert statement with the item financial data
	_, err = tx.Exec(insertItemFinancialQuery, item.ItemID, item.BuyPrice, gstOnBuy, buyPriceWithoutGST, item.MRPPrice, gstOnMRP, mrpPriceWithoutGST, item.Margin, item.CurrentSchemeID)
	if err != nil {
		return nil, fmt.Errorf("error inserting into item_financial: %w", err)
	}

	return item, nil
}
