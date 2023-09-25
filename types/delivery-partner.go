package types

import (
	"time"
)

// Basic
type DeliveryPartner struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Store_ID  int       `json:"store_id"`
	Phone     string    `json:"phone"`
	Address   string    `json:"address"`
	Created_At time.Time `json:"created_at"`
}

type Create_DeliveryPartner struct {
	Name     string `json:"name"`
	Store_ID int    `json:"store_id"`
	Phone    string `json:"phone"`
	Address  string `json:"address"`
}

type Update_DeliveryPartner struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Store_ID int    `json:"store_id"`
	Phone    string `json:"phone"`
	Address  string `json:"address"`
}

type Delete_DeliveryPartner struct {
	ID    int    `json:"id"`
	Phone string `json:"phone"`
}

func New_DeliveryPartner(name string, storeID int, phone string, address string) (*Create_DeliveryPartner, error) {
	return &Create_DeliveryPartner{
		Name:     name,
		Store_ID: storeID,
		Phone:    phone,
		Address:  address,
	}, nil
}

func New_Update_DeliveryPartner(id int, name string, storeID int, phone string, address string) (*Update_DeliveryPartner, error) {
	return &Update_DeliveryPartner{
		ID:       id,
		Name:     name,
		Store_ID: storeID,
		Phone:    phone,
		Address:  address,
	}, nil
}
