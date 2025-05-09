package store

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
)

func (s *PostgresStore) Search_Items(query string) ([]*types.Get_Items_By_CategoryID_And_StoreID_noCategory, error) {
	fmt.Println("Entered Search_Items")

	lowerQuery := strings.ToLower(query) // Ensure the query is case-insensitive
	fuzzyMatchQuery := "%" + lowerQuery + "%"

	_, err := s.db.Exec("SELECT set_limit(0.15);") // Set a lower similarity threshold
	if err != nil {
		return nil, fmt.Errorf("error setting similarity threshold: %v", err)
	}

	rows, err := s.db.Query(`
    SELECT
        item.id,
        MAX(item.name) AS name,
        MAX(item_financial.mrp_price) AS mrp_price,
        MAX(item_store.discount) AS discount,
        MAX(item_store.store_price) AS store_price,
        MAX(store.name) AS store_name,
        MAX(item_store.stock_quantity) AS stock_quantity,
        MAX(item_store.locked_quantity) AS locked_quantity,
        MAX((SELECT image_url FROM item_image WHERE item_image.item_id = item.id ORDER BY order_position LIMIT 1)) AS image_url,
        MAX(brand.name) AS brand_name,
        MAX(item.quantity) AS quantity,
        MAX(item.unit_of_quantity) AS unit_of_quantity,
        MAX(item.created_at) AS created_at,
        MAX(item.created_by) AS created_by
    FROM item
    INNER JOIN item_store ON item.id = item_store.item_id
    INNER JOIN item_financial ON item.id = item_financial.item_id
    LEFT JOIN store ON item_store.store_id = store.id
    LEFT JOIN brand ON item.brand_id = brand.id
    LEFT JOIN item_category ON item.id = item_category.item_id
    LEFT JOIN category ON item_category.category_id = category.id
    WHERE lower(item.name) % $1 OR
          lower(brand.name) % $1 OR
          lower(item.description) % $1 OR
          lower(category.name) % $1
    GROUP BY item.id
    ORDER BY MAX(similarity(lower(item.name), $1) * 0.4 + 
                 similarity(lower(brand.name), $1) * 0.3 +
                 similarity(lower(item.description), $1) * 0.2 +
                 similarity(lower(category.name), $1) * 0.2) DESC, 
             MAX(item_store.stock_quantity) DESC
    `, fuzzyMatchQuery)

	if err != nil {
		return nil, fmt.Errorf("error executing search query: %v", err)
	}
	defer rows.Close()

	var items []*types.Get_Items_By_CategoryID_And_StoreID_noCategory
	for rows.Next() {
		var item types.Get_Items_By_CategoryID_And_StoreID_noCategory
		var imageURL sql.NullString
		var createdBy sql.NullInt64
		var mrpPrice sql.NullFloat64

		err := rows.Scan(
			&item.ID,
			&item.Name,
			&mrpPrice,
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
			&createdBy,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning row: %v", err)
		}

		// Handle null values
		if mrpPrice.Valid {
			item.MRP_Price = mrpPrice.Float64
		} else {
			item.MRP_Price = 0.0
		}

		if imageURL.Valid {
			item.Image = imageURL.String
		} else {
			item.Image = ""
		}

		if createdBy.Valid {
			item.Created_By = int(createdBy.Int64)
		} else {
			item.Created_By = 0
		}

		item.Store_Price = item.MRP_Price - item.Discount

		items = append(items, &item)
	}

	_, err = s.db.Exec("SELECT set_limit(0.3);") // Reset the similarity threshold
	if err != nil {
		return nil, fmt.Errorf("error resetting similarity threshold: %v", err)
	}

	return items, nil
}

func (s *PostgresStore) ManagerSearchItem(name string) ([]ManagerSearchItem, error) {
	var items []ManagerSearchItem

	query := `
	SELECT i.id, i.name, COALESCE(i.barcode, '') AS barcode, i.description, i.quantity, i.unit_of_quantity, b.name AS brand_name, i.brand_id, COALESCE(if.mrp_price, 0) AS mrp_price, array_remove(array_agg(DISTINCT ii.image_url), NULL) AS images
	FROM item i
	LEFT JOIN brand b ON i.brand_id = b.id
	LEFT JOIN item_financial if ON i.id = if.item_id
	LEFT JOIN item_image ii ON i.id = ii.item_id
	WHERE LOWER(i.name) LIKE LOWER($1)
	GROUP BY i.id, b.name, if.mrp_price
	`

	rows, err := s.db.Query(query, "%"+name+"%")
	if err != nil {
		return nil, fmt.Errorf("error executing search query: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var item ManagerSearchItem
		var images pq.StringArray // Properly using pq.StringArray to handle the array of images

		// Scan the row with the correct type for the images column
		err := rows.Scan(&item.Id, &item.Name, &item.Barcode, &item.Description, &item.Quantity, &item.UnitOfQuantity, &item.BrandName, &item.BrandId, &item.MRPPrice, &images)
		if err != nil {
			return nil, fmt.Errorf("error scanning row: %w", err)
		}

		// Convert pq.StringArray directly to a slice of strings
		item.Images = []string(images)

		items = append(items, item)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating through rows: %w", err)
	}

	return items, nil
}

type ManagerSearchItem struct {
	Id             int      `json:"id"`
	Name           string   `json:"name"`
	Description    string   `json:"description"`
	Quantity       int      `json:"size"`
	UnitOfQuantity string   `json:"unit_of_quantity"`
	BrandName      string   `json:"brand_name"`
	BrandId        int      `json:"brand_id"`
	MRPPrice       float64  `json:"mrp_price"`
	Images         []string `json:"images"`
	Barcode        string   `json:"barcode"`
}
