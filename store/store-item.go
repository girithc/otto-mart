package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) CreateItemTable(tx *sql.Tx) error {
	// First, let's define the ENUM type for unit
	unitEnumQuery := `DO $$ BEGIN
						CREATE TYPE unit_enum AS ENUM ('g', 'mg', 'ml', 'l', 'kg', 'ct');
					EXCEPTION
						WHEN duplicate_object THEN null;
					END $$;`
	_, err := tx.Exec(unitEnumQuery)
	if err != nil {
		return fmt.Errorf("error creating unit_enum type: %w", err)
	}

	// Now, create the item table with quantity, unit, and description fields
	query := `CREATE TABLE IF NOT EXISTS item(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL UNIQUE,
		brand_id INT REFERENCES brand(id) ON DELETE CASCADE,
		quantity INT NOT NULL,
		unit_of_quantity unit_enum,
		description TEXT DEFAULT 'description',
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)
	`

	_, err = tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item table: %w", err)
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
            mrp_price DECIMAL(10, 2) NOT NULL,
            store_price DECIMAL(10, 2) NOT NULL,
            discount DECIMAL(10, 2) NOT NULL,
            store_id INT REFERENCES store(id) ON DELETE CASCADE,
            stock_quantity INT NOT NULL,
            locked_quantity INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by INT,
            CHECK (mrp_price = store_price + discount),
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
		istore.mrp_price, 
		istore.discount, 
		istore.store_price,
		s.name AS store_name,
		c.name AS category_name,
		istore.stock_quantity,
		istore.locked_quantity,
		ii.image_url, 
		i.created_at,
		i.created_by
	FROM item i
	JOIN item_category ic ON i.id = ic.item_id
	JOIN item_store istore ON i.id = istore.item_id
	JOIN brand b ON i.brand_id = b.id
	JOIN store s ON istore.store_id = s.id
	JOIN category c ON ic.category_id = c.id
	LEFT JOIN item_image ii ON i.id = ii.item_id AND ii.order_position = 1
	WHERE ic.category_id = $1 AND istore.store_id = $2
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
			&item.Image,
			&item.Created_At,
			&item.Created_By,
		)
		if err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("error scanning row: %w", err)
		}
		items = append(items, item)
	}

	err = tx.Commit()
	if err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return items, nil
}

func (s *PostgresStore) Get_Item_By_ID(id int) (*types.Get_Item, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback()

	item := &types.Get_Item{}

	// Get basic item data, brand name, and description
	query := `SELECT i.id, i.name, i.quantity, i.unit_of_quantity, b.name, i.description, i.created_at, i.created_by FROM item i
              LEFT JOIN brand b ON i.brand_id = b.id
              WHERE i.id = $1`
	row := tx.QueryRow(query, id)
	if err := row.Scan(&item.ID, &item.Name, &item.Quantity, &item.Unit_Of_Quantity, &item.Brand, &item.Description, &item.Created_At, &item.Created_By); err != nil {
		return nil, err
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
