package store

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)


type PostgresStore struct {
	db *sql.DB
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

	errShoppingCart := s.CreateShoppingCartTable()
	if errShoppingCart != nil{
		return errShoppingCart
	}else {
		fmt.Println("Success - Created Shopping Cart Table")
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

	errUser := s.Create_User_Table()
	if errUser != nil{
		return errUser
	} else {
		fmt.Println("Success - Created User Table")
	}

	//fmt.Println("Exiting Init() -- db.go")
	return nil
}

