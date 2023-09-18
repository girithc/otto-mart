package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"pronto-go/types"
)

func (s *Server) Handle_Checkout_Cart(res http.ResponseWriter, req *http.Request) error {
	
	new_req := new(types.Checkout)
	
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Checkout_Cart()")
		return err
	}

	// Check if cart_id exists
	cart_id_exists, err := s.store.DoesCartExist(new_req.Cart_Id) 
	if err != nil {
		return err
	}

	if(cart_id_exists) {
		//checkout, err := s.store.Checkout_Items()
	}
	
	return nil
}