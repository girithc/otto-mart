package types

type Item_Store struct {
	CartId int `json:"cart_id"`
}

type Item_Store_Unlock struct {
	CartId int  `json:"cart_id"`
	Unlock bool `json:"unlock"`
}
