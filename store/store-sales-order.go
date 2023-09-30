package store

import (
	"database/sql"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateSalesOrderTable() error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists sales_order (
		id SERIAL PRIMARY KEY,
		delivery_partner_id INT REFERENCES Delivery_Partner(id) ON DELETE CASCADE,
		cart_id INT REFERENCES Shopping_Cart(id) ON DELETE CASCADE NOT NULL,
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		customer_id INT REFERENCES Customer(id) ON DELETE CASCADE NOT NULL,
		delivery_address TEXT NOT NULL,
		order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := s.db.Exec(query)

	// fmt.Println("Exiting CreateItemTable")

	return err
}

func (s *PostgresStore) Get_All_Sales_Orders() ([]*types.Sales_Order, error) {
	rows, err := s.db.Query("SELECT * FROM sales_order")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	salesOrders := []*types.Sales_Order{}

	for rows.Next() {
		order, err := scanIntoSalesOrder(rows)
		if err != nil {
			return nil, err
		}
		salesOrders = append(salesOrders, order)
	}

	return salesOrders, nil
}

func scanIntoSalesOrder(rows *sql.Rows) (*types.Sales_Order, error) {
	order := new(types.Sales_Order)

	// Use sql.NullInt64 for nullable integer columns.
	var deliveryPartnerID sql.NullInt64

	err := rows.Scan(
		&order.ID,
		&deliveryPartnerID,
		&order.CartID,
		&order.StoreID,
		&order.CustomerID,
		&order.DeliveryAddress,
		&order.OrderDate,
	)

	// Assign the value from the sql.NullInt64 to the Sales_Order struct's field if it's valid (i.e., not NULL).
	if deliveryPartnerID.Valid {
		order.DeliveryPartnerID = int(deliveryPartnerID.Int64)
	} else {
		order.DeliveryPartnerID = 0 // Or whatever default or sentinel value you want for NULLs.
	}

	return order, err
}
