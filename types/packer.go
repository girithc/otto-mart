package types

import (
	"time"

	"github.com/google/uuid"
)

type PackerLogin struct {
	Message string `json:"message"`
	Type    string `json:"type"`
	Packer  PackerData
}

type PackerData struct {
	ID         int       `json:"id"`
	Name       string    `json:"name"`
	Phone      string    `json:"phone"`
	Address    string    `json:"address"`
	Created_At time.Time `json:"created_at"`
	Token      uuid.UUID `json:"token"`
}

type PackerFCM struct {
	Phone string `json:"phone"`
	FCM   string `json:"fcm"`
}

type PackerPhone struct {
	Phone string `json:"phone"`
}

type PackerGetOrderItems struct {
	SalesOrderId int `json:"sales_order_id"`
}
