package types

type Cart_Item struct {
	ID int `json:"id"`
	CartId int `json:"cart_id"`
	ItemId int `json:"item_id"`
	Quantity int `json:"quantity"`
}

type Create_Cart_Item struct {
	CartId int `json:"cart_id"`
	ItemId int `json:"item_id"`
	Quantity int `json:"quantity"`
}

type Remove_Cart_Item struct {
	CartId int `json:"cart_id"`
	ItemId int `json:"item_id"`
	Quantity int `json:"quantity"`
}


func New_Cart_Item(cart_id int, item_id int, quantity int)(*Cart_Item, error) {
	return &Cart_Item{
	CartId: cart_id,
	ItemId: item_id,
	Quantity: quantity,
}, nil
}