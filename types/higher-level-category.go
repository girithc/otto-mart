package types

type Higher_Level_Category struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	Image      string `json:"image"`
	Position   int    `json:"position"`
	Created_At string `json:"created_at"`
	Created_By int    `json:"created_by"` // Updated to sql.NullInt64
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

func New_Update_Higher_Level_Category(name string, id int) (*Update_Higher_Level_Category, error) {
	return &Update_Higher_Level_Category{
		Name: name,
		ID:   id,
	}, nil
}
