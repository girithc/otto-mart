package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) Search_Items(query string) ([]*types.Search_Item_Result, error) {
	fmt.Println("Entered Search_Items")

	// Join with item_category, item_image, and item_store tables to get all the required details
	rows, err := s.db.Query(`
	SELECT 
		item.id, 
		item.name, 
		item_store.price, 
		item_store.store_id, 
		item_category.category_id, 
		item_store.stock_quantity, 
		item_store.locked_quantity, 
		item_image.image_url, 
		item.created_at, 
		item.created_by 
	FROM item
	LEFT JOIN item_category ON item.id = item_category.item_id
	LEFT JOIN item_image ON item.id = item_image.item_id
	LEFT JOIN item_store ON item.id = item_store.item_id
	WHERE item.name ILIKE '%' || $1 || '%'
	ORDER BY item_image.order_position LIMIT 1   -- Ensure to get only the first image if there are multiple images
`, query)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	items := []*types.Search_Item_Result{}
	for rows.Next() {
		item := &types.Search_Item_Result{}
		var imageURL sql.NullString
		err := rows.Scan(
			&item.ID,
			&item.Name,
			&item.Price,
			&item.Store_ID,
			&item.Category_ID,
			&item.Stock_Quantity,
			&item.Locked_Quantity,
			&imageURL,
			&item.Created_At,
			&item.Created_By,
		)
		if err != nil {
			return nil, err
		}
		item.Image = imageURL.String // Assigning the image URL (handling NULL)
		items = append(items, item)
	}

	return items, nil
}
