package types

import (
	"time"
)

// Basic
type Item struct {
	ID               int       `json:"id"`
	Name             string    `json:"name"`
	MRP_Price        float64   `json:"mrp_price"`
	Discount         float64   `json:"discount"`
	Store_Price      float64   `json:"store_price"`
	Description      string    `json:"description"`
	Store            string    `json:"store"`
	Category         string    `json:"category"`
	Stock_Quantity   int       `json:"stock_quantity"`
	Locked_Quantity  int       `json:"locked_quantity"`
	Image            string    `json:"image"`
	Brand            string    `json:"brand"`
	Quantity         int       `json:"quantity"`
	Unit_Of_Quantity string    `json:"unit_of_quantity"`
	Created_At       time.Time `json:"created_at"`
	Created_By       int       `json:"created_by"`
}

type Get_Item struct {
	ID               int       `json:"id"`
	Name             string    `json:"name"`
	MRP_Price        float64   `json:"mrp_price"`
	Discount         float64   `json:"discount"`
	Store_Price      float64   `json:"store_price"`
	Description      string    `json:"description"`
	Stores           []string  `json:"stores"`
	Categories       []string  `json:"categories"`
	Stock_Quantity   int       `json:"stock_quantity"`
	Locked_Quantity  int       `json:"locked_quantity"`
	Images           []string  `json:"images"`
	Brand            string    `json:"brand"`
	Quantity         int       `json:"quantity"`
	Unit_Of_Quantity string    `json:"unit_of_quantity"`
	Created_At       time.Time `json:"created_at"`
	Created_By       int       `json:"created_by"`
}

type Create_Item struct {
	Name             string  `json:"name"`
	MRP_Price        float64 `json:"mrp_price"`
	Discount         float64 `json:"discount"`
	Store_Price      float64 `json:"store_price"`
	Description      string  `json:"description"`
	Store            string  `json:"store"`
	Category         string  `json:"category"`
	Brand            string  `json:"brand"`
	Image            string  `json:"image"`
	Quantity         int     `json:"quantity"`
	Unit_Of_Quantity string  `json:"unit_of_quantity"`
	Stock_Quantity   int     `json:"stock_quantity"`
}

type Update_Item struct {
	ID             int     `json:"id"`
	Name           string  `json:"name"`
	MRP_Price      float64 `json:"mrp_price"`
	Discount       float64 `json:"discount"`
	Store_Price    float64 `json:"store_price"`
	Description    string  `json:"description"`
	Store          string  `json:"store"`
	Category       string  `json:"category"`
	Image          string  `json:"image"`
	Order_Position int     `json:"order_position"`
	Stock_Quantity int     `json:"stock_quantity"`
}

type Delete_Item struct {
	ID int `json:"id"`
}

// Custom
type Get_Items_By_CategoryID_And_StoreID struct {
	ID               int       `json:"id"`
	Name             string    `json:"name"`
	MRP_Price        float64   `json:"mrp_price"`
	Discount         float64   `json:"discount"`
	Store_Price      float64   `json:"store_price"`
	Store            string    `json:"store"`
	Category         string    `json:"category"`
	Stock_Quantity   int       `json:"stock_quantity"`
	Locked_Quantity  int       `json:"locked_quantity"`
	Image            string    `json:"image"`
	Brand            string    `json:"brand"`
	Quantity         int       `json:"quantity"`
	Unit_Of_Quantity string    `json:"unit_of_quantity"`
	Created_At       time.Time `json:"created_at"`
	Created_By       int       `json:"created_by"`
}

func New_Item(name string, mrp_price float64, discount float64, store_price float64, category string, store string, brand string, stock_quantity int, image string, description string, quantity int, unit_of_quantity string) (*Item, error) {
	return &Item{
		Name:             name,
		MRP_Price:        mrp_price,
		Store_Price:      store_price,
		Discount:         discount,
		Category:         category,
		Store:            store,
		Description:      description,
		Brand:            brand,
		Stock_Quantity:   stock_quantity,
		Image:            image,
		Quantity:         quantity,
		Unit_Of_Quantity: unit_of_quantity,
		Created_By:       1,
	}, nil
}

func New_Update_Item(id int, name string, mrp_price float64, store_price float64, discount float64, category string, store string, stock_quantity int, image string) (*Update_Item, error) {
	return &Update_Item{
		ID:             id,
		Name:           name,
		MRP_Price:      mrp_price,
		Discount:       discount,
		Store_Price:    store_price,
		Category:       category,
		Store:          store,
		Stock_Quantity: stock_quantity,
		Image:          image,
	}, nil
}
