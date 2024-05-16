package types

import (
	"database/sql"
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
	OrderDate         string        `json:"order_date"`
}

type Sales_Order_Details struct {
	ID                int    `json:"id"`
	DeliveryPartnerID int    `json:"delivery_partner_id"`
	CartID            int    `json:"cart_id"`
	StoreID           int    `json:"store_id"`
	StoreName         string `json:"store_name"`
	CustomerID        int    `json:"customer_id"`
	CustomerName      string `json:"customer_name"`
	CustomerPhone     string `json:"customer_phone"`
	DeliveryAddress   string `json:"delivery_address"`
	OrderDate         string `json:"order_date"`
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
	ID          int         `json:"id"`
	CartID      int         `json:"cart_id"`
	StoreID     int         `json:"store_id"`
	CustomerID  int         `json:"customer_id"`
	AddressID   int         `json:"address_id"`
	Paid        bool        `json:"paid"`
	PaymentType string      `json:"payment_type"`
	OrderDate   string      `json:"order_date"`
	NewCartID   int         `json:"new_cart_id"`
	Products    []SOProduct `json:"products"`
	Store       SOStore     `json:"store"`
	Address     SOAddress   `json:"address"`
	OTP         string      `json:"otp"`
	OrderType   string      `json:"order_type"`
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
	CreatedAt        string         `json:"created_at"`
	Available        bool           `json:"available"`
	CurrentLocation  sql.NullString `json:"current_location"`
	ActiveDeliveries int            `json:"active_deliveries"`
	LastAssignedTime string         `json:"last_assigned_time"`
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

type RecentOrder struct {
	StoreID     int    `json:"store_id"`
	PackerPhone string `json:"packer_phone"`
}

type AcceptOrderItem struct {
	PackerPhone  string `json:"packer_phone"`
	SalesOrderID int    `json:"sales_order_id"`
	Barcode      string `json:"barcode"`
	StoreId      int    `json:"store_id"`
}

type SpaceOrder struct {
	PackerPhone  string `json:"packer_phone"`
	SalesOrderID int    `json:"sales_order_id"`
	Location     int    `json:"location"`
	StoreId      int    `json:"store_id"`
	Image        string `json:"image_url"`
}

type PackedOrderItem struct {
	PackerPhone  string `json:"packer_phone"`
	SalesOrderID int    `json:"sales_order_id"`
}

type CompletePackOrder struct {
	PackerPhone  string `json:"packer_phone"`
	SalesOrderID int    `json:"sales_order_id"`
	StoreID      int    `json:"store_id"`
}

type CancelRecentOrder struct {
	StoreID     int    `json:"store_id"`
	PackerPhone string `json:"packer_phone"`
	OrderID     int    `json:"order_id"`
}

type CustomerPhone struct {
	Phone string `json:"phone"`
}

type DPOrderDetails struct {
	ID                int            `json:"id"`
	DeliveryPartnerID int            `json:"delivery_partner_id"`
	CartID            int            `json:"cart_id"`
	PaymentType       string         `json:"payment_type"`
	StoreID           int            `json:"store_id"`
	StoreName         string         `json:"store_name"`
	CustomerID        int            `json:"customer_id"`
	CustomerName      string         `json:"customer_name"`
	CustomerPhone     string         `json:"customer_phone"`
	Subtotal          int            `json:"subtotal"`
	OrderDate         string         `json:"order_date"`
	DeliveryAddress   AddressDetails `json:"delivery_address"`
}

type AddressDetails struct {
	StreetAddress  string  `json:"street_address"`
	LineOneAddress string  `json:"line_one_address"`
	LineTwoAddress string  `json:"line_two_address"`
	Latitude       float64 `json:"latitude"`
	Longitude      float64 `json:"longitude"`
}
