package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) CreateItemTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists item(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		brand_id INT REFERENCES brand(id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating brand table: %w", err)
	}

	return err
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
	storeIDQuery := `SELECT id FROM store WHERE name = $1`
	var storeID int
	err = tx.QueryRow(storeIDQuery, p.Store).Scan(&storeID)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error deriving store id: %w", err)
	}

	// Derive category_id using category name
	categoryIDQuery := `SELECT id FROM category WHERE name = $1`
	var categoryID int
	err = tx.QueryRow(categoryIDQuery, p.Category).Scan(&categoryID)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error deriving category id: %w", err)
	}

	// Check if item with the same name already exists
	existingItemQuery := `SELECT i.id, i.name, istore.mrp_price, s.name, c.name, istore.stock_quantity, 
                          istore.locked_quantity, ii.image_url, i.created_at, i.created_by 
                          FROM item i 
                          JOIN item_store istore ON i.id = istore.item_id 
                          JOIN store s ON istore.store_id = s.id 
                          JOIN item_category ic ON i.id = ic.item_id 
                          JOIN category c ON ic.category_id = c.id 
                          JOIN item_image ii ON i.id = ii.item_id 
                          WHERE i.name = $1`
	existingItem := &types.Item{}
	err = tx.QueryRow(existingItemQuery, p.Name).Scan(&existingItem.ID, &existingItem.Name, &existingItem.Price, &existingItem.Store,
		&existingItem.Category, &existingItem.Stock_Quantity, &existingItem.Locked_Quantity, &existingItem.Image,
		&existingItem.Created_At, &existingItem.Created_By)
	if err == nil { // Item exists
		tx.Rollback()
		return existingItem, nil
	} else if err != sql.ErrNoRows {
		tx.Rollback()
		return nil, fmt.Errorf("error querying item: %w", err)
	}

	newItem := &types.Item{
		Name:            p.Name,
		Price:           p.Price,
		Store:           p.Store,
		Category:        p.Category,
		Stock_Quantity:  p.Stock_Quantity,
		Locked_Quantity: p.Locked_Quantity,
		Image:           p.Image,
		Created_By:      p.Created_By,
	}

	// Insert into item table
	query := `INSERT INTO item (name, created_by) 
              VALUES ($1, $2) 
              RETURNING id, created_at`
	err = tx.QueryRow(query, newItem.Name, newItem.Created_By).Scan(&newItem.ID, &newItem.Created_At)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item: %w", err)
	}

	// Insert into item_store table
	query = `INSERT INTO item_store (item_id, price, store_id, stock_quantity, locked_quantity, created_by) 
             VALUES ($1, $2, $3, $4, $5, $6)`
	_, err = tx.Exec(query, newItem.ID, newItem.Price, storeID, newItem.Stock_Quantity, newItem.Locked_Quantity, newItem.Created_By)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_store: %w", err)
	}

	// Insert into item_category table
	query = `INSERT INTO item_category (item_id, category_id, created_by) 
             VALUES ($1, $2, $3)`
	_, err = tx.Exec(query, newItem.ID, categoryID, newItem.Created_By)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_category: %w", err)
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
	SELECT 
	i.id, i.name, istore.mrp_price, istore.store_id, istore.stock_quantity, istore.locked_quantity, i.created_at, i.created_by,
	array_agg(ic.category_id) as category_ids,
	array_agg(ii.image_url) as images
	FROM item i
	LEFT JOIN item_store istore ON i.id = istore.item_id
	LEFT JOIN item_category ic ON i.id = ic.item_id
	LEFT JOIN item_image ii ON i.id = ii.item_id
	GROUP BY i.id, istore.mrp_price, istore.store_id, istore.stock_quantity, istore.locked_quantity
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
		var categoryIDs pq.Int64Array
		var images pq.StringArray

		err := rows.Scan(
			&item.ID,
			&item.Name,
			&item.Price,
			&item.Store_ID,
			&item.Stock_Quantity,
			&item.Locked_Quantity,
			&item.Created_At,
			&item.Created_By,
			&categoryIDs,
			&images,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning row into item: %w", err)
		}

		// Convert pq.Int64Array to []int
		item.Category_IDs = make([]int, len(categoryIDs))
		for i, v := range categoryIDs {
			item.Category_IDs[i] = int(v)
		}

		// Convert pq.StringArray to []string
		item.Image = make([]string, len(images))
		copy(item.Image, images)

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
	SELECT i.id, i.name, istore.mrp_price, istore.store_id, ic.category_id, ii.image_url, istore.stock_quantity
	FROM item i
	JOIN item_category ic ON i.id = ic.item_id
	JOIN item_store istore ON i.id = istore.item_id
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
		err := rows.Scan(&item.ID, &item.Name, &item.Price, &item.Store_ID, &item.Category_ID, &item.Image, &item.Stock_Quantity)
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
	defer tx.Rollback() // if everything goes well, this will be a no-op

	item := &types.Get_Item{}

	// Get basic item data
	query := `SELECT id, name, created_at, created_by FROM item WHERE id = $1`
	row := tx.QueryRow(query, id)
	if err := row.Scan(&item.ID, &item.Name, &item.Created_At, &item.Created_By); err != nil {
		return nil, err
	}

	// Get category_ids
	query = `SELECT category_id FROM item_category WHERE item_id = $1`
	rows, err := tx.Query(query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var categoryID int
		if err := rows.Scan(&categoryID); err != nil {
			return nil, err
		}
		item.Category_IDs = append(item.Category_IDs, categoryID)
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
		item.Image = append(item.Image, imageUrl)
	}

	// Get store-related details. Assuming an item can be in multiple stores. Adjust if needed.
	query = `SELECT store_id, price, stock_quantity, locked_quantity 
             FROM item_store WHERE item_id = $1`
	rows, err = tx.Query(query, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		// For simplicity, using the last record. If an item can be in multiple stores, you need more logic.
		if err := rows.Scan(&item.Store_ID, &item.Price, &item.Stock_Quantity, &item.Locked_Quantity); err != nil {
			return nil, err
		}
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
	query := `UPDATE item SET name = $1 WHERE id = $2`
	if _, err := tx.Exec(query, item.Name, item.ID); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item: %w", err)
	}

	// Update item_store table
	query = `UPDATE item_store SET price = $1, stock_quantity = $2 WHERE item_id = $3`
	if _, err := tx.Exec(query, item.Price, item.Stock_Quantity, item.ID); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item_store: %w", err)
	}

	// Update item_image table. We assume the first image is being updated
	query = `UPDATE item_image SET image_url = $1 WHERE item_id = $2 AND order_position = 1`
	if _, err := tx.Exec(query, item.Image, item.ID); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item_image: %w", err)
	}

	// Update item_category table. We assume that the item is only linked to one category for simplicity
	query = `UPDATE item_category SET category_id = $1 WHERE item_id = $2`
	if _, err := tx.Exec(query, item.Category_ID, item.ID); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating item_category: %w", err)
	}

	tx.Commit()
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
