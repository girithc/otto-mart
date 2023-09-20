package types

type Checkout struct {
	Cart_Id int `json:"cart_id"`
}

type Checkout_Cart_Item struct {
	Item_Id int `json:"item_id"`
	Quantity int `json:"quantity"`
}