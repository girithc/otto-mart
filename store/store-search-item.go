package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) Search_Items(query string) ([]*types.Get_Items_By_CategoryID_And_StoreID_noCategory, error) {
	fmt.Println("Entered Search_Items")

	rows, err := s.db.Query(`
    SELECT 
    item.id, 
    item.name, 
    item_store.mrp_price, 
    item_store.discount,
    item_store.store_price,
    store.name AS store_name,
    item_store.stock_quantity, 
    item_store.locked_quantity, 
    (SELECT image_url FROM item_image WHERE item_image.item_id = item.id ORDER BY order_position LIMIT 1) AS image_url,
    brand.name AS brand_name,
    item.quantity,
    item.unit_of_quantity,
    item.created_at, 
    item.created_by 
FROM item
LEFT JOIN item_store ON item.id = item_store.item_id
LEFT JOIN store ON item_store.store_id = store.id
LEFT JOIN brand ON item.brand_id = brand.id
WHERE item.name ILIKE '%' || $1 || '%'
ORDER BY item.id
 
    `, query)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	items := []*types.Get_Items_By_CategoryID_And_StoreID_noCategory{}
	for rows.Next() {
		item := &types.Get_Items_By_CategoryID_And_StoreID_noCategory{}
		var imageURL sql.NullString

		err := rows.Scan(
			&item.ID,
			&item.Name,
			&item.MRP_Price,
			&item.Discount,
			&item.Store_Price,
			&item.Store,
			&item.Stock_Quantity,
			&item.Locked_Quantity,
			&imageURL,
			&item.Brand,
			&item.Quantity,
			&item.Unit_Of_Quantity,
			&item.Created_At,
			&item.Created_By,
		)
		if err != nil {
			return nil, err
		}
		item.Image = imageURL.String
		items = append(items, item)
	}

	return items, nil
}
