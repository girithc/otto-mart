package types

type Store struct {
	ID         int     `json:"id"`
	Name       string  `json:"name"`
	Address    string  `json:"address"`
	Latitude   float64 `json:"latitude"`  // Added field for latitude
	Longitude  float64 `json:"longitude"` // Added field for longitude
	Created_At string  `json:"created_at"`
	Created_By int     `json:"created_by"`
}

type Create_Store struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}

type StoreId struct {
	StoreId   int `json:"store_id"`
	AddressId int `json:"address_id"`
}

type Update_Store struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Address string `json:"address"`
}

type Delete_Store struct {
	ID int `json:"id"`
}

func New_Store(name string, address string) (*Store, error) {
	return &Store{
		Name:       name,
		Address:    address,
		Created_By: 1,
	}, nil
}

func New_Update_Store(name string, address string, id int) (*Update_Store, error) {
	return &Update_Store{
		Name:    name,
		Address: address,
		ID:      id,
	}, nil
}
