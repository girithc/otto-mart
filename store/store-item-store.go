package store

import (
	"fmt"
	"time"
)

func (s *PostgresStore) RemoveLockQuantities(cart_id int) ([]itemStoreRecord, error) {
	query := `
		UPDATE item_store
		SET locked_quantity = 0
		FROM cart_item
		WHERE cart_item.item_id = item_store.id AND cart_item.cart_id = $1
		RETURNING item_store.*
	`

	rows, err := s.db.Query(query, cart_id)
	if err != nil {
		return nil, fmt.Errorf("error updating and fetching locked_quantity: %w", err)
	}
	defer rows.Close()

	var records []itemStoreRecord
	for rows.Next() {
		var record itemStoreRecord
		err = rows.Scan(&record.ID, &record.ItemID, &record.MRPPrice, &record.StorePrice, &record.Discount, &record.StoreID, &record.StockQuantity, &record.LockedQuantity, &record.CreatedAt, &record.CreatedBy)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}

	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return records, nil
}

func (s *PostgresStore) UnlockQuantities(cart_id int) ([]itemStoreRecord, error) {
	query := `
        WITH updated AS (
            UPDATE item_store
            SET stock_quantity = stock_quantity + locked_quantity,
                locked_quantity = 0
            FROM cart_item
            WHERE cart_item.item_id = item_store.id AND cart_item.cart_id = $1
            RETURNING item_store.*
        )
        SELECT * FROM updated
    `

	rows, err := s.db.Query(query, cart_id)
	if err != nil {
		return nil, fmt.Errorf("error updating and fetching locked_quantity: %w", err)
	}
	defer rows.Close()

	var records []itemStoreRecord
	for rows.Next() {
		var record itemStoreRecord
		err = rows.Scan(&record.ID, &record.ItemID, &record.MRPPrice, &record.StorePrice, &record.Discount, &record.StoreID, &record.StockQuantity, &record.LockedQuantity, &record.CreatedAt, &record.CreatedBy)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}

	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return records, nil
}

// Assuming your item_store record structure looks something like this:
type itemStoreRecord struct {
	ID             int
	ItemID         int
	MRPPrice       float64
	StorePrice     float64
	Discount       float64
	StoreID        int
	StockQuantity  int
	LockedQuantity int
	CreatedAt      time.Time
	CreatedBy      int
}
