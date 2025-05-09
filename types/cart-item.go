package types

type Cart_Item struct {
	ID       int `json:"id"`
	CartId   int `json:"cart_id"`
	ItemId   int `json:"item_id"`
	Quantity int `json:"quantity"`
}
type CartDetails struct {
	CartId               int    `json:"cart_id"`
	ItemId               int    `json:"item_id"`
	Quantity             int    `json:"quantity"`
	ItemCost             int    `json:"item_cost"`
	DeliveryFee          int    `json:"delivery_fee"`
	PlatformFee          int    `json:"platform_fee"`
	SmallOrderFee        int    `json:"small_order_fee"`
	RainFee              int    `json:"rain_fee"`
	HighTrafficSurcharge int    `json:"high_traffic_surcharge"`
	PackagingFee         int    `json:"packaging_fee"`
	PeakTimeSurcharge    int    `json:"peak_time_surcharge"`
	Subtotal             int    `json:"subtotal"`
	Discounts            int    `json:"discounts"`
	OutOfStock           bool   `json:"out_of_stock"`
	FreeDeliveryAmount   int    `json:"free_delivery_amount"`
	PromoCode            string `json:"promo_code"`
}

type CartItemResponse struct {
	CartDetails   *CartDetails           `json:"cart_details"`
	CartItemsList []*Cart_Item_Item_List `json:"cart_items_list"`
}

type Create_Cart_Item struct {
	CartId     int `json:"cart_id"`
	ItemId     int `json:"item_id"`
	Quantity   int `json:"quantity"`
	CustomerId int `json:"customer_id"`
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
	SoldPrice      int    `json:"sold_price"`
	Quantity       int    `json:"quantity"`
	Image          string `json:"image"`
	Stock_Quantity int    `json:"stock_quantity"`
	InStock        bool   `json:"in_stock"`
}

type Get_Cart_Items_Item_List struct {
	CartId int  `json:"cart_id"`
	Items  bool `json:"items"`
}

type CustomerAndCartId struct {
	Customer_Id int `json:"customer_id"`
	Cart_Id     int `json:"cart_id"`
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
