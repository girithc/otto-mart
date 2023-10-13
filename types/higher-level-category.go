package types

import "time"

type Higher_Level_Category struct {
	ID         int       `json:"id"`
	Name       string    `json:"name"`
	Image      string    `json:"image"`
	Position   int       `json:"position"`
	Created_At time.Time `json:"created_at"`
	Created_By int       `json:"created_by"`
}

type Create_Higher_Level_Category struct {
	Name     string `json:"name"`
	Image    string `json:"image"`
	Position int    `json:"position"`
}

type Update_Higher_Level_Category struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type Delete_Higher_Level_Category struct {
	ID int `json:"id"`
}

func New_Higher_Level_Category(name string, image string) (*Higher_Level_Category, error) {
	return &Higher_Level_Category{
		Name:       name,
		Image:      image,
		Position:   1,
		Created_By: 1,
	}, nil
}

func New_Update_Higher_Level_Category(name string, id int) (*Update_Higher_Level_Category, error) {
	return &Update_Higher_Level_Category{
		Name: name,
		ID:   id,
	}, nil
}
