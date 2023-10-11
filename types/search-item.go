package types

import "time"

type Search_Item struct {
	Name string `json:"name"`
}

type Search_Item_Result struct {
	ID              int       `json:"id"`
	Name            string    `json:"name"`
	Price           float64   `json:"price"`
	Store_ID        string    `json:"store_id"`
	Category_ID     string    `json:"category_id"`
	Stock_Quantity  int       `json:"stock_quantity"`
	Locked_Quantity int       `json:"locked_quantity"`
	Image           string    `json:"image"`
	Created_At      time.Time `json:"created_at"`
	Created_By      int       `json:"created_by"`
}
