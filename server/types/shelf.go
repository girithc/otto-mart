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

type AssignItemShelf struct {
	StoreID     int    `json:"store_id"`
	ItemBarcode string `json:"item_barcode"`
	Horizontal  int    `json:"horizontal"`
	Vertical    string `json:"vertical"`
}
