package types

type Cart_Item struct {
	ID       int `json:"id"`
	CartId   int `json:"cart_id"`
	ItemId   int `json:"item_id"`
	Quantity int `json:"quantity"`
}
type Cart_Item_Cart struct {
	ID                   int     `json:"id"`
	CartId               int     `json:"cart_id"`
	ItemId               int     `json:"item_id"`
	Quantity             int     `json:"quantity"`
	ItemCost             float64 `json:"item_cost"`
	DeliveryFee          float64 `json:"delivery_fee"`
	PlatformFee          float64 `json:"platform_fee"`
	SmallOrderFee        float64 `json:"small_order_fee"`
	RainFee              float64 `json:"rain_fee"`
	HighTrafficSurcharge float64 `json:"high_traffic_surcharge"`
	PackagingFee         float64 `json:"packaging_fee"`
	PeakTimeSurcharge    float64 `json:"peak_time_surcharge"`
	Subtotal             float64 `json:"subtotal"`
	Discounts            float64 `json:"discounts"`
	Total                float64 `json:"total"`
}

type Create_Cart_Item struct {
	CartId   int `json:"cart_id"`
	ItemId   int `json:"item_id"`
	Quantity int `json:"quantity"`
}

type Remove_Cart_Item struct {
	CartId   int `json:"cart_id"`
	ItemId   int `json:"item_id"`
	Quantity int `json:"quantity"`
}

type Get_Cart_Items struct {
	CartId int `json:"cart_id"`
}

type Cart_Item_Item_List struct {
	Id             int    `json:"id"`
	Name           string `json:"name"`
	Price          int    `json:"price"`
	Quantity       int    `json:"quantity"`
	Image          string `json:"image"`
	Stock_Quantity int    `json:"stock_quantity"`
}

type Get_Cart_Items_Item_List struct {
	CartId int  `json:"cart_id"`
	Items  bool `json:"items"`
}

type Cart_Item_Customer_Id struct {
	Customer_Id int `json:"customer_id"`
}

type Cart_Item_Quantity struct {
	Quantity int `json:"quantity"`
}

func New_Cart_Item(cart_id int, item_id int, quantity int) (*Cart_Item, error) {
	return &Cart_Item{
		CartId:   cart_id,
		ItemId:   item_id,
		Quantity: quantity,
	}, nil
}
