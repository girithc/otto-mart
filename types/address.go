package types

import "database/sql"

type Address1 struct {
	Id               int     `json:"id"`
	Customer_Id      int     `json:"customer_id"`
	Street_Address   string  `json:"street_address"`
	Line_One_Address string  `json:"line_one"`
	Line_Two_Address string  `json:"line_two"`
	City             string  `json:"city"`
	State            string  `json:"state"`
	Zipcode          string  `json:"zip"`
	Is_Default       bool    `json:"is_default"`
	Latitude         float64 `json:"latitude"`
	Longitude        float64 `json:"longitude"`
	Created_At       string  `json:"created_at"`
}

type Address struct {
	Id               int            `json:"id"`
	Customer_Id      int            `json:"customer_id"`
	Street_Address   sql.NullString `json:"street_address"`
	Line_One_Address sql.NullString `json:"line_one"`
	Line_Two_Address sql.NullString `json:"line_two"`
	City             sql.NullString `json:"city"`
	State            sql.NullString `json:"state"`
	Zipcode          sql.NullString `json:"zip"`
	Is_Default       bool           `json:"is_default"`
	Latitude         float64        `json:"latitude"`
	Longitude        float64        `json:"longitude"`
	Created_At       string         `json:"created_at"`
}

type Default_Address struct {
	Id               int     `json:"id"`
	Customer_Id      int     `json:"customer_id"`
	Street_Address   string  `json:"street_address"`
	Line_One_Address string  `json:"line_one"`
	Line_Two_Address string  `json:"line_two"`
	City             string  `json:"city"`
	State            string  `json:"state"`
	Zipcode          string  `json:"zip"`
	Is_Default       bool    `json:"is_default"`
	Latitude         float64 `json:"latitude"`
	Longitude        float64 `json:"longitude"`
	Created_At       string  `json:"created_at"`
	Deliverable      bool    `json:"deliverable"`
	StoreId          int     `json:"store_id"`
	HDistance        float64 `json:"h_distance"`
	PGDistance       float64 `json:"gis_distance"`
	CartId           int     `json:"cart_id"`
}

type Create_Address struct {
	Customer_Id      string  `json:"customer_id"`
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

type MakeDefaultAddress struct {
	Address_Id  int  `json:"address_id"`
	Customer_Id int  `json:"customer_id"`
	Is_Default  bool `json:"is_default"`
}

type DeliverToAddress struct {
	Address_Id  int `json:"address_id"`
	Customer_Id int `json:"customer_id"`
}

type Deliverable struct {
	Deliverable bool    `json:"deliverable"`
	StoreId     int     `json:"store_id"`
	CartId      int     `json:"cart_id"`
	HDistance   float64 `json:"h_distance"`
	PGDistance  float64 `json:"gis_distance"`
}

type Delete_Address struct {
	Customer_Id int `json:"customer_id"`
	Address_Id  int `json:"address_id"`
}
