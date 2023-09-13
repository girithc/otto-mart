package store

import (
	"database/sql"
	"log"
	"pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateCustomerTable() error {
	//fmt.Println("Entered CreateCustomerTable")

	query := `create table if not exists customer (
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		phone VARCHAR(10) NOT NULL, 
		address TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateCustomerTable")

	return err
}

func (s *PostgresStore) Create_Customer(user *types.Create_Customer) (*types.Customer, error) {
	
	
	query := `insert into customer
	(name, phone, address) 
	values ($1, $2, $3) returning id, name, phone, address, created_at
	`
	rows, err := s.db.Query(
		query,
		"",
		user.Phone, 
		"")

	if err != nil {
		return nil, err
	}


	customers := []*types.Customer{}
	
	for rows.Next() {
		customer, err := scan_Into_Customer(rows)
		if err != nil {
			return nil, err
		}
		customers = append(customers, customer)
	}


	return customers[0], nil
}


func (s *PostgresStore) Get_All_Customers() ([]*types.Customer, error) {
	query := `select * from customer
	`
	rows, err := s.db.Query(
		query)

		if err != nil {
			return nil, err
		}
	
	
		customers := []*types.Customer{}
		
		for rows.Next() {
			customer, err := scan_Into_Customer(rows)
			if err != nil {
				return nil, err
			}
			customers = append(customers, customer)
		}
	
		return customers, nil
}

func(s *PostgresStore) Get_Customer_By_Phone(phone int) (*types.Customer, error) {
	
	rows, err := s.db.Query("select * from customer where phone = $1", phone)

	if err != nil {
		log.Fatal(err)
	}
	
	defer rows.Close()

	customers := []*types.Customer{}

	for rows.Next() {
		customer, err := scan_Into_Customer(rows)
		if err != nil {
			return nil, err
		}
		customers = append(customers, customer)
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	if len(customers) == 0 {
		return nil, nil
	}
 
	return customers[0], nil
}





//Helper
func scan_Into_Customer(rows *sql.Rows) (*types.Customer, error) {
	customer := new(types.Customer)
	err := rows.Scan(
		&customer.ID,
		&customer.Name,
		&customer.Phone,
		&customer.Address,
		&customer.Created_At,
	)

	return customer, err
}

func scan_Into_Update_Customer(rows *sql.Rows) (*types.Update_Customer, error) {
	customer := new(types.Update_Customer)
	error := rows.Scan(
		&customer.Phone,
		&customer.Address,
		&customer.Name,
		&customer.ID,
	)

	return customer, error
} 