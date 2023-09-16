package types

import "time"

type Shopping_Cart struct {
	ID                int       `json:"id"`
	Customer_Id		  int 		`json:"customer_id"`
	Active 		      bool		`json:"active"`
	Created_At        time.Time `json:"created_at"`
}

type Create_Shopping_Cart struct {
	Customer_Id       int       `json:"customer_id"`
}

type Get_Shopping_Cart struct {
	Customer_Id		  int 		`json:"customer_id"`
	Active 		      bool		`json:"active"`
}

func New_Shopping_Cart(customer_id int)(*Create_Shopping_Cart, error) {
	return &Create_Shopping_Cart{
		Customer_Id: customer_id,
}, nil
}