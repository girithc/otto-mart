package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) CreateItemTable() error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists item(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := s.db.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItemCategoryTable() error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists item_category(
		item_id INT REFERENCES item(id) ON DELETE CASCADE,
		category_id INT REFERENCES category(id) ON DELETE CASCADE,
		PRIMARY KEY(item_id, category_id),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := s.db.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item_category table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItemImageTable() error {
	// fmt.Println("Entered CreateItemTable")

	query := `
		create table if not exists item_image(
			id SERIAL PRIMARY KEY,
			item_id INT REFERENCES item(id) ON DELETE CASCADE,
			image_url TEXT NOT NULL,
			order_position INT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			created_by INT,
			UNIQUE (item_id, order_position)   -- Ensure each image has a distinct order for each item
		)`

	_, err := s.db.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item_image table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItemStoreTable() error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists item_store(
		item_id INT REFERENCES item(id) ON DELETE CASCADE,
		price DECIMAL(10, 2) NOT NULL,
		store_id INT REFERENCES store(id) ON DELETE CASCADE,
		stock_quantity INT NOT NULL,
		locked_quantity INT DEFAULT 0,
		PRIMARY KEY(item_id, store_id),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := s.db.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating item_store table: %w", err)
	}

	return err
}

func (s *PostgresStore) CreateItem(p *types.Item) (*types.Item, error) {
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}

	// Insert into item table
	query := `INSERT INTO item (name, created_by) 
              VALUES ($1, $2) 
              RETURNING id, created_at`
	err = tx.QueryRow(query, p.Name, p.Created_By).Scan(&p.ID, &p.Created_At)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item: %w", err)
	}

	// Insert into item_store table
	query = `INSERT INTO item_store (item_id, price, store_id, stock_quantity, locked_quantity, created_by) 
             VALUES ($1, $2, $3, $4, $5, $6)`
	_, err = tx.Exec(query, p.ID, p.Price, p.Store_ID, p.Stock_Quantity, p.Locked_Quantity, p.Created_By)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_store: %w", err)
	}

	// Insert into item_category table
	query = `INSERT INTO item_category (item_id, category_id, created_by) 
             VALUES ($1, $2, $3)`
	_, err = tx.Exec(query, p.ID, p.Category_ID, p.Created_By)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_category: %w", err)
	}

	// Insert into item_image table
	query = `INSERT INTO item_image (item_id, image_url, order_position, created_by) 
             VALUES ($1, $2, $3, $4)`
	_, err = tx.Exec(query, p.ID, p.Image, 1, p.Created_By) // Default order_position set to 1
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error inserting into item_image: %w", err)
	}

	// Commit transaction
	err = tx.Commit()
	if err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return p, nil
}

func (s *PostgresStore) GetItems() ([]*types.Get_Item, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback()

	query := `
	SELECT 
	i.id, i.name, istore.price, istore.store_id, istore.stock_quantity, istore.locked_quantity, i.created_at, i.created_by,
	array_agg(ic.category_id) as category_ids,
	array_agg(ii.image_url) as images
	FROM item i
	LEFT JOIN item_store istore ON i.id = istore.item_id
	LEFT JOIN item_category ic ON i.id = ic.item_id
	LEFT JOIN item_image ii ON i.id = ii.item_id
	GROUP BY i.id, istore.price, istore.store_id, istore.stock_quantity, istore.locked_quantity
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
	SELECT i.id, i.name, istore.price, istore.store_id, ic.category_id, ii.image_url, istore.stock_quantity
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

func scan_Into_Item(rows *sql.Rows) (*types.Item, error) {
	item := new(types.Item)
	err := rows.Scan(
		&item.ID,
		&item.Name,
		&item.Price,
		&item.Store_ID,
		&item.Category_ID,
		&item.Stock_Quantity, // Move Locked_Quantity before Image
		&item.Image,          // Image after Locked_Quantity
		&item.Created_At,
		&item.Created_By,
		&item.Locked_Quantity, // Move Locked_Quantity before Image

	)

	return item, err
}

func scan_Into_Update_Item(rows *sql.Rows) (*types.Update_Item, error) {
	item := new(types.Update_Item)
	error := rows.Scan(
		&item.ID,
		&item.Name,
		&item.Price,
		&item.Category_ID,
		&item.Stock_Quantity,
		&item.Image,
	)

	return item, error
}

func scan_Into_Items_By_CategoryID_And_StoreID(rows *sql.Rows) (*types.Get_Items_By_CategoryID_And_StoreID, error) {
	item := new(types.Get_Items_By_CategoryID_And_StoreID)
	err := rows.Scan(
		&item.ID,
		&item.Name,
		&item.Price,
		&item.Store_ID,
		&item.Category_ID,
		&item.Stock_Quantity,
		&item.Image,
	)

	return item, err
}
