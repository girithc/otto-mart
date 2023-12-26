package types

type CreateShelf struct {
	StoreId    int    `json:"store_id"`
	Horizontal int    `json:"horizontal"`
	Vertical   string `json:"vertical"`
	Barcode    string `json:"barcode"`
}

type GetShelf struct {
	StoreId int `json:"store_id"`
}
