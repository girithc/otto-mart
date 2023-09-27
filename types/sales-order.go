package types

import "time"

type Sales_Order struct {
	ID                int
	DeliveryPartnerID int
	CartID            int
	StoreID           int
	CustomerID        int
	DeliveryAddress   string
	OrderDate         time.Time
}
