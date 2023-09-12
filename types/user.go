package types

import (
	"time"
)

//Basic
type User struct {
	ID                int       `json:"id"`
	Name              string    `json:"name"`
	Phone			  int 		`json:"phone"`
	Created_At        time.Time `json:"created_at"`
}

type Create_User struct {
	Phone			  int 		`json:"phone"`
}

type Update_User struct {
	ID                int       `json:"id"`
	Name              string    `json:"name"`
	Phone			  int 		`json:"phone"`
}

type Delete_User struct {
	ID		int `json:"id"`
}


func New_User(phone int)(*Create_User, error) {
	return &Create_User{
		Phone: phone,
}, nil
}

func New_Update_User(id int, name string, phone int)(*Update_User, error) {
	return &Update_User{
	ID:             id,
	Name: name,
	Phone: phone,
}, nil
}
