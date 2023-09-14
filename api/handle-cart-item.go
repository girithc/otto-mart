package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"pronto-go/types"
)


func(s *Server) Handle_Add_Cart_item(res http.ResponseWriter, req *http.Request) error {
	// Data Extraction
	new_req := new(types.Create_Cart_Item)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Create New_Category_Higher_Level_Mapping()")
		return err
	}
	// Check if cart_id exists
	cart_id_exists, err := s.store.DoesCartExist(new_req.CartId) 
	if err != nil {
		return err
	}
	if(cart_id_exists) {

	}
	//If Exists Check if item_id exists in cart_id
			//If exists add quantity +1 to the same record
			//Else add cart_item record with quantity +1
		//Else Throw Error
	
	return nil
}

func(s *Server) Handle_Delete_Cart_item(res http.ResponseWriter, req *http.Request) error {

	return nil
}