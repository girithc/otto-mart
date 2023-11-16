package types

import (
	"database/sql"
	"time"
)

type Sales_Order struct {
	ID                int           `json:"id"`
	DeliveryPartnerID sql.NullInt64 `json:"delivery_partner_id"`
	CartID            int           `json:"cart_id"`
	StoreID           int           `json:"store_id"`
	CustomerID        int           `json:"customer_id"`
	AddressID         int           `json:"address_id"`
	Paid              bool          `json:"paid"`
	PaymentType       string        `json:"payment_type"`
	OrderDate         time.Time     `json:"order_date"`
}

type Sales_Order_Details struct {
	ID                int       `json:"id"`
	DeliveryPartnerID int       `json:"delivery_partner_id"`
	CartID            int       `json:"cart_id"`
	StoreID           int       `json:"store_id"`
	StoreName         string    `json:"store_name"`
	CustomerID        int       `json:"customer_id"`
	CustomerName      string    `json:"customer_name"`
	CustomerPhone     string    `json:"customer_phone"`
	DeliveryAddress   string    `json:"delivery_address"`
	OrderDate         time.Time `json:"order_date"`
}

type Sales_Order_Delivery_Partner struct {
	ID int `json:"id"`
}
