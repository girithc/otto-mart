package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"pronto-go/types"
)

func (s *Server) Handle_User_Login(res http.ResponseWriter, req *http.Request) error {
	
	//Preprocessing

	new_req := new(types.Create_User)
	
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_User_Login()")
		return err
	}
	
	new_user, err := types.New_User(new_req.Phone);
	fmt.Println(new_user.Phone)

	if err != nil {
		return err
	}

	//Check if User Exists

	user, err := s.store.Get_User_By_Phone(new_user.Phone)

	if err != nil {
		return err
	}

	//User Does Not Exist
	if user == nil {
		fmt.Println("User Does Not Exist")
		user, err := s.store.Create_User(new_req)
		
		if err != nil {
			return err
		}

		return WriteJSON(res, http.StatusOK, user)
	} else { //User Exist 
		fmt.Println("User Exists")
		return WriteJSON(res, http.StatusOK, user)
	}

}