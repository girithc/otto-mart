package types

import "time"

type Brand struct {
	ID         int       `json:"id"`
	Name       string    `json:"name"`
	Created_At time.Time `json:"created_at"`
	Created_By int       `json:"created_by"`
}

type BrandList struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type Create_Brand struct {
	Name string `json:"name"`
}

func New_Brand(name string) (*Brand, error) {
	return &Brand{
		Name:       name,
		Created_By: 1,
	}, nil
}
