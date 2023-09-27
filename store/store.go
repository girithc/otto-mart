package store

import (
	"context"
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)


type PostgresStore struct {
	db *sql.DB
	cancelFuncs map[int]context.CancelFunc
}

func NewPostgresStore() (*PostgresStore, error) {
	//fmt.Println("Entered NewPostgresStore() -- db.go")

	connStr := "user=postgres dbname=prontodb password=g190201 sslmode=disable"
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		//fmt.Println("Exiting (Err) NewPostgresStore() -- db.go")
	
		return nil, err
	}

	if err := db.Ping(); err != nil {
		//fmt.Println("Exiting (db.Ping()) NewPostgresStore() -- db.go")
	
		return nil, err
	}

	//fmt.Println("Exiting NewPostgresStore() -- db.go")
	

	return &PostgresStore{
		db: db,
		cancelFuncs: make(map[int]context.CancelFunc), // Initialize the cancelFuncs map
	}, nil
}

func (s *PostgresStore) Init() error {

	//fmt.Println("Entered Init() -- db.go")

	errCategory := s.Create_Category_Table()
	if errCategory != nil{
		return errCategory
	} else {
		fmt.Println("Success - Created Category Table")
	}

	errStore := s.CreateStoreTable()
	if errStore != nil{
		return errStore
	} else {
		fmt.Println("Success - Created Store Table")
	}

	errItem := s.CreateItemTable()
	if errItem != nil{
		return errItem
	} else {
		fmt.Println("Success - Created Item Table")
	}

	errCustomer := s.CreateCustomerTable()
	if errCustomer != nil{
		return errCustomer
	} else {
		fmt.Println("Success - Created Customer Table")
	}

	errCartItem := s.CreateCartItemTable()
	if errCartItem != nil{
		return errCartItem
	}else {
		fmt.Println("Success - Created Cart Item Table")
	}

	errHigherLevelCategory := s.Create_Higher_Level_Category_Table()
	if errHigherLevelCategory != nil{
		return errHigherLevelCategory
	} else {
		fmt.Println("Success - Created Higher Level Category Table")
	}

	errCategoryHigherLevelMapping := s.Create_Category_Higher_Level_Mapping_Table()
	if errCategoryHigherLevelMapping != nil{
		return errCategoryHigherLevelMapping
	} else {
		fmt.Println("Success - Created Category Higher Level Mapping Table")
	}

	errDeliveryPartner := s.CreateDeliveryPartnerTable()
	if errDeliveryPartner != nil{
		return errDeliveryPartner
	} else {
		fmt.Println("Success - Created Delivery Partner Table")
	}

	errShoppingCart := s.CreateShoppingCartTable()
	if errShoppingCart != nil{
		return errShoppingCart
	}else {
		fmt.Println("Success - Created Shopping Cart Table")
	}

	errSalesOrder := s.CreateSalesOrderTable()
	if errSalesOrder != nil {
		return errSalesOrder
	} else {
		fmt.Println("Success  - Created Sales Order Table")
	}

	// Check and add the constraint only if it doesn't exist
    constraintQuery := `
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT constraint_name 
            FROM information_schema.table_constraints 
            WHERE table_name = 'shopping_cart' AND constraint_name = 'shopping_cart_order_id_fkey'
        ) THEN
            ALTER TABLE shopping_cart ADD CONSTRAINT shopping_cart_order_id_fkey FOREIGN KEY (order_id) REFERENCES sales_order(id) ON DELETE CASCADE;
        END IF;
    END
    $$;
    `

    if _, err := s.db.Exec(constraintQuery); err != nil {
        return fmt.Errorf("failed to add constraint to shopping_cart: %w", err)
    }

    // ... [your other code, if any]

    return nil
}

