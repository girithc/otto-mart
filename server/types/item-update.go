package types

type Item_Barcode struct {
	ItemId  int    `json:"item_id"`
	Barcode string `json:"barcode"`
}

type ItemAddStock struct {
	ItemId   int `json:"item_id"`
	AddStock int `json:"add_stock"`
}

type Barcode struct {
	Barcode string `json:"barcode"`
}
