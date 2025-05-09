package types

type Category struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	Promotion  bool   `json:"promotion"`
	Image      string `json:"image"`
	Position   int    `json:"position"`
	Created_At string `json:"created_at"`
	Created_By int    `json:"created_by"`
}

type Create_Category struct {
	Name      string `json:"name"`
	Image     string `json:"image"`
	Promotion bool   `json:"promotion"`
}

type Update_Category struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Image string `json:"image"`
}

type Delete_Category struct {
	ID int `json:"id"`
}

type Category_Parent_Id struct {
	ID int `json:"id"`
}

func New_Category(name string, image string, promotion bool) (*Category, error) {
	return &Category{
		Name:       name,
		Image:      image,
		Promotion:  promotion,
		Position:   1,
		Created_By: 1,
	}, nil
}

func New_Update_Category(name string, id int) (*Update_Category, error) {
	return &Update_Category{
		Name: name,
		ID:   id,
	}, nil
}

func New_Category_Parent_Id(id int) (*Category_Parent_Id, error) {
	return &Category_Parent_Id{
		ID: id,
	}, nil
}
