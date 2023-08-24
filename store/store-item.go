package store

import (
	"database/sql"
	"fmt"
	"pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateItemTable() error {
	//fmt.Println("Entered CreateItemTable")

	query := `create table if not exists item(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		price DECIMAL(10, 2) NOT NULL,
		store_id INT REFERENCES Store(id) ON DELETE CASCADE,
		category_id INT REFERENCES Category(id) ON DELETE CASCADE,
		stock_quantity INT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateItemTable")

	return err
}

func (s *PostgresStore) Create_Item(p *types.Item) (*types.Item,error) {
	query := `insert into item 
	(name, price, store_id, category_id, stock_quantity, created_by)
	values ($1, $2, $3, $4, $5, $6)
	returning id, name, price, store_id, category_id, stock_quantity, created_at, created_by`
	rows , err := s.db.Query(
		query,
		p.Name,
		p.Price,
		p.Store_ID,
		p.Category_ID,
		p.Stock_Quantity, 
		p.Created_By)

	fmt.Println("CheckPoint 1")

	if err != nil {
		return nil, err
	}

	fmt.Println("CheckPoint 2")

	items := []*types.Item{}

	for rows.Next() {
		item, err := scan_Into_Item(rows)
		if err != nil {
			return nil, err
		}

		items = append(items, item)
	}

	fmt.Println("CheckPoint 3")

	return items[0], err
}

func (s *PostgresStore) Get_Items() ([]*types.Item, error) {
	
	fmt.Println("Entered Get_Items")
	
	rows, err := s.db.Query("select * from item")

	if err != nil {
		return nil, err
	}

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

func (s *PostgresStore) Get_Items_By_CategoryID_And_StoreID(category_id int, store_id int) ([]*types.Get_Items_By_CategoryID_And_StoreID, error) {
	
	fmt.Println("Entered Get_Items_By_CategoryID_And_StoreID")
	rows, err := s.db.Query("select id, name, price, store_id, category_id, stock_quantity from item where category_id = $1 AND store_id = $2", category_id, store_id)

	if err != nil {
		return nil, err
	}

	items := []*types.Get_Items_By_CategoryID_And_StoreID{}
	for rows.Next() {
		item, err := scan_Into_Items_By_CategoryID_And_StoreID(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items , nil
}

func (s *PostgresStore) Get_Item_By_ID(id int) (*types.Item, error) {
	row, err := s.db.Query("select * from item where id = $1", id)
	if err != nil {
		return nil, err
	}

	for row.Next() {
		return scan_Into_Item(row)
	}

	return nil, fmt.Errorf("item with id = [%d] not found", id)
}

func (s *PostgresStore) Update_Item(item *types.Update_Item) (*types.Update_Item,error) {
	query := `update item
	set 
	name = $1, 
	price = $2, 
	category_id = $3, 
	stock_quantity = $4
	where id = $5 
	returning id, name, price, category_id, stock_quantity`
	
	rows, err := s.db.Query(
		query, 
		item.Name,
		item.Price,
		item.Category_ID,
		item.Stock_Quantity,
		item.ID,
	)

	if err != nil {
		return nil, err
	}

	items := []*types.Update_Item{}
	
	for rows.Next() {
		item, err := scan_Into_Update_Item(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	

	return items[0], nil
}

func (s *PostgresStore) Delete_Item(id int) error {
	_, err := s.db.Query("delete from item where id = $1", id)
	return err
}

func scan_Into_Item(rows *sql.Rows) (*types.Item, error) {
	item := new(types.Item)
	err := rows.Scan(
		&item.ID,
		&item.Name,
		&item.Price,
		&item.Store_ID,
		&item.Category_ID, 
		&item.Stock_Quantity,
		&item.Created_At,
		&item.Created_By,
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
	)

	return item, err
}