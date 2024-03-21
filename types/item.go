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
	Category         []string  `json:"category"`
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

type Get_Item_Barcode struct {
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
	Barcode          string    `json:"barcode"`
}

type Create_Item struct {
	Name             string   `json:"name"`
	MRP_Price        float64  `json:"mrp_price"`
	Discount         float64  `json:"discount"`
	Store_Price      float64  `json:"store_price"`
	Description      string   `json:"description"`
	Store            string   `json:"store"`
	Category         []string `json:"category"`
	Brand            string   `json:"brand"`
	Image            string   `json:"image"`
	Quantity         int      `json:"quantity"`
	Unit_Of_Quantity string   `json:"unit_of_quantity"`
	Stock_Quantity   int      `json:"stock_quantity"`
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

type AddItemStockStore struct {
	AddStock int `json:"add_stock"`
	ItemId   int `json:"item_id"`
	StoreId  int `json:"store_id"`
}

type GetItemAdd struct {
	Barcode string `json:"barcode"`
	StoreId int    `json:"store_id"`
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
	Images           []string  `json:"image"`
	Brand            string    `json:"brand"`
	Quantity         int       `json:"quantity"`
	Unit_Of_Quantity string    `json:"unit_of_quantity"`
	Created_At       time.Time `json:"created_at"`
	Created_By       int       `json:"created_by"`
}

type Get_Items_By_CategoryID_And_StoreID_noCategory struct {
	ID               int       `json:"id"`
	Name             string    `json:"name"`
	MRP_Price        float64   `json:"mrp_price"`
	Discount         float64   `json:"discount"`
	Store_Price      float64   `json:"store_price"`
	Store            string    `json:"store"`
	Stock_Quantity   int       `json:"stock_quantity"`
	Locked_Quantity  int       `json:"locked_quantity"`
	Image            string    `json:"image"`
	Brand            string    `json:"brand"`
	Quantity         int       `json:"quantity"`
	Unit_Of_Quantity string    `json:"unit_of_quantity"`
	Created_At       time.Time `json:"created_at"`
	Created_By       int       `json:"created_by"`
}

func New_Item(name string, mrp_price float64, discount float64, store_price float64, category []string, store string, brand string, stock_quantity int, image string, description string, quantity int, unit_of_quantity string) (*Item, error) {
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

type ItemAddQuick struct {
	Name          string `json:"name"`
	BrandName     string `json:"brand_name"`
	Quantity      int    `json:"quantity"`
	Barcode       string `json:"barcode"`
	Unit          string `json:"unit"`
	Description   string `json:"description"`
	CreatedBy     int    `json:"created_by"`
	CategoryId    int    `json:"category_id"`
	StoreId       int    `json:"store_id"`
	MrpPrice      int    `json:"mrp_price"`
	StorePrice    int    `json:"store_price"`
	Discount      int    `json:"discount"`
	StockQuantity int    `json:"stock_quantity"`
}

type ItemEdit struct {
	ID          int      `json:"id"`
	Name        string   `json:"name"`
	Categories  []string `json:"categories"`
	BrandID     int      `json:"brand_id"`
	Description string   `json:"description"`
	Size        int      `json:"size"`
	Unit        string   `json:"unit"`
}

type ItemFinancials struct {
	ItemID          int     `json:"item_id"`
	BuyPrice        float64 `json:"buy_price"`
	MRPPrice        float64 `json:"mrp_price"`
	GSTRate         float64 `json:"gst_rate"` // GST rate as a percentage
	CreatedBy       int     `json:"created_by"`
	Margin          float64 `json:"margin"`            // Margin as a percentage
	CurrentSchemeID int     `json:"current_scheme_id"` // Optional, based on your requirements
}

type ItemFinance struct {
	ItemID   int     `json:"item_id"`
	BuyPrice float64 `json:"buy_price"`
	MRPPrice float64 `json:"mrp_price"`
	GST      float64 `json:"gst"`
	Margin   float64 `json:"margin"`
}

type ItemBasic struct {
	Name           string   `json:"name"`
	BrandId        int      `json:"brand_id"`
	Quantity       int      `json:"quantity"`
	UnitOfQuantity string   `json:"unit_of_quantity"`
	CategoryNames  []string `json:"category_names"`
	Description    string   `json:"description"`
}

type FindItemBasic struct {
	Barcode string `json:"barcode"`
	StoreID int    `json:"store_id"`
}

type CreateOrderBasic struct {
	CartId int `json:"cart_id"`
}
type GetOrderBasic struct {
	StoreId int    `json:"store_id"`
	OTP     string `json:"otp"`
}

type CompleteOrderBasic struct {
	CartId        int    `json:"cart_id"`
	CustomerPhone string `json:"customer_phone"`
}

type LoadItemBasic struct {
	ItemID   int `json:"item_id"`
	Quantity int `json:"quantity"`
	StoreID  int `json:"store_id"`
}

type ItemBarcodeBasic struct {
	ItemID  int    `json:"item_id"`
	Barcode string `json:"barcode"`
}
type ItemBarcodeBasicReturn struct {
	ItemID   int    `json:"item_id"`
	Barcode  string `json:"barcode"`
	ItemName string `json:"item_name"`
}

type ItemBasicReturn struct {
	Name           string   `json:"name"`
	BrandId        int      `json:"brand_id"`
	Quantity       int      `json:"quantity"`
	UnitOfQuantity string   `json:"unit_of_quantity"`
	Description    string   `json:"description"`
	CategoryNames  []string `json:"category_names"`
	Id             int      `json:"id"`
}
