package types

type Category_Higher_Level_Mapping struct {
	ID                       int    `json:"id"`
	Higher_Level_Category_ID int    `json:"higher_level_category_id"`
	Category_ID              int    `json:"category_id"`
	Created_At               string `json:"created_at"`
	Created_By               int    `json:"created_by"`
}

type Create_Category_Higher_Level_Mapping struct {
	Higher_Level_Category_ID int `json:"higher_level_category_id"`
	Category_ID              int `json:"category_id"`
}

type Update_Category_Higher_Level_Mapping struct {
	ID                       int `json:"id"`
	Higher_Level_Category_ID int `json:"higher_level_category_id"`
	Category_ID              int `json:"category_id"`
}

type Delete_Category_Higher_Level_Mapping struct {
	ID int `json:"id"`
}

func New_Category_Higher_Level_Mapping(higher_level_category_id int, category_id int) (*Category_Higher_Level_Mapping, error) {
	return &Category_Higher_Level_Mapping{
		Higher_Level_Category_ID: higher_level_category_id,
		Category_ID:              category_id,
		Created_By:               1,
	}, nil
}

func New_Update_Category_Higher_Level_Mapping(higher_level_category_id int, category_id int, id int) (*Update_Category_Higher_Level_Mapping, error) {
	return &Update_Category_Higher_Level_Mapping{
		Higher_Level_Category_ID: higher_level_category_id,
		Category_ID:              category_id,
		ID:                       id,
	}, nil
}
