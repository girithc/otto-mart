package types

import "time"

type Address struct {
	Id               int       `json:"id"`
	Customer_Id      int       `json:"customer_id"`
	Street_Address   string    `json:"street_address"`
	Line_One_Address string    `json:"line_one"`
	Line_Two_Address string    `json:"line_two"`
	City             string    `json:"city"`
	State            string    `json:"state"`
	Zipcode          string    `json:"zip"`
	Latitude         float64   `json:"latitude"`
	Longitude        float64   `json:"longitude"`
	Created_At       time.Time `json:"created_at"`
}

type Create_Address struct {
	Customer_Id      int     `json:"customer_id"`
	Street_Address   string  `json:"street_address"`
	Line_One_Address string  `json:"line_one"`
	Line_Two_Address string  `json:"line_two"`
	City             string  `json:"city"`
	State            string  `json:"state"`
	Zipcode          string  `json:"zip"`
	Latitude         float64 `json:"latitude"`
	Longitude        float64 `json:"longitude"`
}

type Address_Customer_Id struct {
	Customer_Id int `json:"customer_id"`
}
