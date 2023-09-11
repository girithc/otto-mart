package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"pronto-go/types"
)

func (s *Server) Handle_User_Login(res http.ResponseWriter, req *http.Request) error {
	
	new_req := new(types.Create_User)
	
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_User_Login()")
		return err
	}
	
	new_user, err := types.New_User(new_req.Name, new_req.Phone);
	fmt.Println(new_user)

	if err != nil {
		return err
	}
	//category, err := s.store.Create_User(new_user); 
	
	if err != nil {
		return err
	}


	return err;
	//return WriteJSON(res, http.StatusOK, category)
}