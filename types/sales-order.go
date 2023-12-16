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
	DeliveryPartnerId int `json:"delivery_partner_id"`
}

type Sales_Order_Customer struct {
	CustomerId int `json:"customer_id"`
}

type SalesOrderRecent struct {
	CartID     int `json:"cart_id"`
	CustomerId int `json:"customer_id"`
}

type SalesOrderStore struct {
	StoreId int `json:"store_id"`
}

type SalesOrderStoreAndOrder struct {
	StoreId int `json:"store_id"`
	OrderId int `json:"order_id"`
}

type Sales_Order_Cart struct {
	ID                int               `json:"id"`
	DeliveryPartnerID sql.NullInt64     `json:"delivery_partner_id"`
	CartID            int               `json:"cart_id"`
	StoreID           int               `json:"store_id"`
	CustomerID        int               `json:"customer_id"`
	AddressID         int               `json:"address_id"`
	Paid              bool              `json:"paid"`
	PaymentType       string            `json:"payment_type"`
	OrderDate         time.Time         `json:"order_date"`
	NewCartID         int               `json:"new_cart_id"`
	DeliveryPartner   SODeliveryPartner `json:"delivery_partner"`
	Products          []SOProduct       `json:"products"`
	Store             SOStore           `json:"store"`
	Address           SOAddress         `json:"address"`
}

type SalesOrderIDCustomerID struct {
	SalesOrderID int `json:"sales_order_id"`
	CustomerID   int `json:"customer_id"`
}

type SODeliveryPartner struct {
	ID               int            `json:"id"`
	Name             string         `json:"name"`
	FcmToken         string         `json:"fcm_token"`
	StoreID          int            `json:"store_id"`
	Phone            string         `json:"phone"`
	Address          string         `json:"address"`
	CreatedAt        time.Time      `json:"created_at"`
	Available        bool           `json:"available"`
	CurrentLocation  sql.NullString `json:"current_location"`
	ActiveDeliveries int            `json:"active_deliveries"`
	LastAssignedTime time.Time      `json:"last_assigned_time"`
}

type SOProduct struct {
	ID             int    `json:"id"`
	ItemID         int    `json:"item_id"`
	Quantity       int    `json:"quantity"`
	Name           string `json:"name"`
	BrandID        int    `json:"brand_id"`
	ItemQuantity   int    `json:"item_quantity"`
	UnitOfQuantity string `json:"unit_of_quantity"`
	Description    string `json:"description"`
}

type SOStore struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Address string `json:"address"`
}

type SOAddress struct {
	ID             int     `json:"id"`
	Latitude       float64 `json:"latitude"`
	Longitude      float64 `json:"longitude"`
	StreetAddress  string  `json:"street_address"`
	LineOneAddress string  `json:"line_one_address"`
	LineTwoAddress string  `json:"line_two_address"`
	City           string  `json:"city"`
	State          string  `json:"state"`
	Zipcode        string  `json:"zipcode"`
	IsDefault      bool    `json:"is_default"`
}
