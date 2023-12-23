package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreatePackerItemTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS packer_item (
        id SERIAL PRIMARY KEY,
        item_id INT NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        packer_id INT NOT NULL REFERENCES packer(id) ON DELETE CASCADE,
        packing_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        quantity INT NOT NULL CHECK (quantity > 0),
        sales_order_id INT NOT NULL REFERENCES sales_order(id) ON DELETE CASCADE,
        store_id INT NOT NULL REFERENCES store(id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`

	_, err := tx.Exec(query)
	if err != nil {
		return fmt.Errorf("error creating packer_item table: %w", err)
	}
	return nil
}

func (s *PostgresStore) PackerPackItem(barcode string, packerPhone string, orderId int, storeId int) (PackerItemResponse, error) {
	var response PackerItemResponse
	var allItemsPacked bool

	// Retrieve packer_id from packer table using packerPhone
	var packerId int
	packerIdQuery := `SELECT id FROM packer WHERE phone = $1`
	err := s.db.QueryRow(packerIdQuery, packerPhone).Scan(&packerId)
	if err != nil {
		if err == sql.ErrNoRows {
			return response, fmt.Errorf("no packer found with phone %s", packerPhone)
		}
		return response, fmt.Errorf("error querying packer_id: %w", err)
	}

	// Retrieve item_id from item table using barcode
	var itemId int
	itemIdQuery := `SELECT id FROM item WHERE barcode = $1`
	err = s.db.QueryRow(itemIdQuery, barcode).Scan(&itemId)
	if err != nil {
		if err == sql.ErrNoRows {
			return response, fmt.Errorf("no item found with barcode %s", barcode)
		}
		return response, fmt.Errorf("error querying item_id: %w", err)
	}

	// Retrieve required quantity from cart_item table
	var requiredQuantity int
	cartItemQuery := `SELECT ci.quantity FROM cart_item ci
                      JOIN sales_order so ON ci.cart_id = so.cart_id
                      WHERE so.id = $1 AND ci.item_id = $2`
	err = s.db.QueryRow(cartItemQuery, orderId, itemId).Scan(&requiredQuantity)
	if err != nil {
		return response, fmt.Errorf("error querying required item quantity: %w", err)
	}

	// Retrieve already packed quantity
	var packedQuantity int
	packedQuery := `SELECT SUM(quantity) FROM packer_item
                    WHERE sales_order_id = $1 AND item_id = $2
                    GROUP BY item_id`
	err = s.db.QueryRow(packedQuery, orderId, itemId).Scan(&packedQuantity)
	if err != nil && err != sql.ErrNoRows {
		return response, fmt.Errorf("error querying packed item quantity: %w", err)
	}

	// Compare and insert if necessary
	if requiredQuantity > packedQuantity {
		// Insert a new record into the packer_item table
		insertQuery := `INSERT INTO packer_item (item_id, packer_id, sales_order_id, quantity, store_id) VALUES ($1, $2, $3, $4, $5)`
		_, err = s.db.Exec(insertQuery, itemId, packerId, orderId, 1, storeId)
		if err != nil {
			return response, fmt.Errorf("error inserting into packer_item table: %w", err)
		}
	}

	

	if (requiredQuantity == packedQuantity) || (requiredQuantity == packedQuantity+1) {
		allItemsPacked = true
	} else {
		allItemsPacked = false
	}

	// Fetch all packer_item records for the sales_order_id and group by item_id to sum the quantity
	groupedItemsQuery := `
    SELECT item_id, SUM(quantity) as quantity
    FROM packer_item
    WHERE sales_order_id = $1
    GROUP BY item_id`
	rows, err := s.db.Query(groupedItemsQuery, orderId)
	if err != nil {
		return response, fmt.Errorf("error querying grouped packer_item records: %w", err)
	}
	defer rows.Close()

	var itemList []PackerItemDetail
	for rows.Next() {
		var itemDetail PackerItemDetail
		err = rows.Scan(&itemDetail.ItemID, &itemDetail.Quantity)
		if err != nil {
			return response, fmt.Errorf("error scanning grouped packer_item records: %w", err)
		}
		itemDetail.PackerID = packerId
		itemDetail.OrderID = orderId
		itemList = append(itemList, itemDetail)
	}

	// Check for any error encountered during iteration
	if err = rows.Err(); err != nil {
		return response, err
	}

	response = PackerItemResponse{
		ItemList:  itemList,
		Success:   true,
		AllPacked: allItemsPacked,
	}

	return response, nil
}

func (s *PostgresStore) GetAllPackedItems(packerPhone string, orderId int) ([]PackerItemDetail, error) {
	var details []PackerItemDetail

	// Retrieve packer_id from packer table using packerPhone
	var packerId int
	packerIdQuery := `SELECT id FROM packer WHERE phone = $1`
	err := s.db.QueryRow(packerIdQuery, packerPhone).Scan(&packerId)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no packer found with phone %s", packerPhone)
		}
		return nil, fmt.Errorf("error querying packer_id: %w", err)
	}

	// Query for all packed items by the packer for the given order, grouping by item_id and summing quantities
	itemsQuery := `
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM packer_item
    WHERE packer_id = $1 AND sales_order_id = $2
    GROUP BY item_id`
	rows, err := s.db.Query(itemsQuery, packerId, orderId)
	if err != nil {
		return nil, fmt.Errorf("error querying packed items: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var detail PackerItemDetail
		err = rows.Scan(&detail.ItemID, &detail.Quantity)
		if err != nil {
			return nil, fmt.Errorf("error reading packed items: %w", err)
		}
		detail.PackerID = packerId
		detail.OrderID = orderId
		details = append(details, detail)
	}

	// Check for any error encountered during iteration
	if err = rows.Err(); err != nil {
		return nil, err
	}

	return details, nil
}

type PackerItemResponse struct {
	ItemList  []PackerItemDetail `json:"item_list"`
	Success   bool               `json:"success"`
	AllPacked bool               `json:"all_packed"`
}

type PackerItemDetail struct {
	ItemID   int `json:"item_id"`
	PackerID int `json:"packer_id"`
	OrderID  int `json:"order_id"`
	Quantity int `json:"quantity"`
}
