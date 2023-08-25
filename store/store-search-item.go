package store

import (
	"fmt"
	"pronto-go/types"

	_ "github.com/lib/pq"
)


func (s *PostgresStore) Search_Items(query string) ([]*types.Item, error) {
	fmt.Println("Entered Search_Items")

	rows, err := s.db.Query(`
	SELECT * FROM item
	WHERE name ILIKE '%' || $1 || '%'
`, query)
	if err != nil {
		return nil, err
	}
	
	defer rows.Close()

	items := []*types.Item{}
	for rows.Next() {
		item, err := scan_Into_Item(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items , nil
}