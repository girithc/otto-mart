package types

import (
	"time"
)

//Basic
type Customer struct {
	ID                int       `json:"id"`
	Name              string    `json:"name"`
	Phone			  int 		`json:"phone"`
	Address 		 string		`json:"address"`
	Created_At        time.Time `json:"created_at"`
}

type Customer_With_Cart struct {
	ID                int       `json:"id"`
	Name              string    `json:"name"`
	Phone			  int 		`json:"phone"`
	Address 		 string		`json:"address"`
	Created_At        time.Time `json:"created_at"`
	Cart_Id				int     `json:"cart_id"`
	Store_Id			int 	`json:"store_id"`
}

type Create_Customer struct {
	Phone			  int 		`json:"phone"`
}

type Update_Customer struct {
	ID                int       `json:"id"`
	Name              string    `json:"name"`
	Phone			  int 		`json:"phone"`
	Address 		 string		`json:"address"`
}

type Delete_User struct {
	ID		int `json:"id"`
	Phone			  int 		`json:"phone"`
}


func New_Customer(phone int)(*Create_Customer, error) {
	return &Create_Customer{
		Phone: phone,
}, nil
}

func New_Update_Customer(id int, name string, phone int, address string)(*Update_Customer, error) {
	return &Update_Customer{
	ID:             id,
	Name: name,
	Phone: phone,
	Address: address,
}, nil
}
