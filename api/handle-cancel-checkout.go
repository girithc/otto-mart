package api

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (s *Server) Handle_Cancel_Checkout_Cart(res http.ResponseWriter, req *http.Request) error {

	var requestBody map[string]int
	if err := json.NewDecoder(req.Body).Decode(&requestBody); err != nil {
		return err
	}
        
	cartID, exists := requestBody["cart_id"]
	if !exists {
		http.Error(res, "cart_id is required", http.StatusBadRequest)
		return fmt.Errorf("cart_id is required")
	}

	err := s.store.Cancel_Checkout(cartID);
	if err != nil {
		return err
	}
	
	err = s.store.ResetLockedQuantities(cartID)
	if err != nil {
		return err
	}
	
	
	res.WriteHeader(http.StatusOK)
	res.Write([]byte("Checkout canceled and quantities reset."))
	return nil
}
