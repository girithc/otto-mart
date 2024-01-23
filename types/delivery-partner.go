package types

import (
	"time"
)

// Basic
type Delivery_Partner struct {
	ID         int       `json:"id"`
	Name       string    `json:"name"`
	FCM_Token  string    `json:"fcm_token"`
	Store_ID   int       `json:"store_id"`
	Phone      string    `json:"phone"`
	Address    string    `json:"address"`
	Created_At time.Time `json:"created_at"`
	Available  string    `json:"available"`
}

type Create_Delivery_Partner struct {
	Name     string `json:"name"`
	Phone    string `json:"phone"`
	Store_ID int    `json:"store_id"`
}

type FCM_Token_Delivery_Partner struct {
	Phone     string `json:"phone"`
	Fcm_Token string `json:"fcm_token"`
}

type DeliveryPartnerPhone struct {
	Phone string `json:"phone"`
}
type DeliveryPartnerAcceptOrder struct {
	Phone        string `json:"phone"`
	SalesOrderId int    `json:"sales_order_id"`
}

type Update_Delivery_Partner struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Store_ID int    `json:"store_id"`
	Phone    int    `json:"phone"`
	Address  string `json:"address"`
}

type Delete_Delivery_Partner struct {
	ID    int    `json:"id"`
	Phone string `json:"phone"`
}

func New_Delivery_Partner(phone string, name string, store_id int) (*Create_Delivery_Partner, error) {
	return &Create_Delivery_Partner{
		Phone:    phone,
		Name:     name,
		Store_ID: store_id,
	}, nil
}

func New_Update_Delivery_Partner(id int, name string, storeID int, phone int, address string) (*Update_Delivery_Partner, error) {
	return &Update_Delivery_Partner{
		ID:       id,
		Name:     name,
		Store_ID: storeID,
		Phone:    phone,
		Address:  address,
	}, nil
}
