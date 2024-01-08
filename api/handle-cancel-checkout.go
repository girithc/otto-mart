package api

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (s *Server) HandleCancelCheckoutCart(res http.ResponseWriter, req *http.Request) error {
	var requestBody map[string]interface{}
	if err := json.NewDecoder(req.Body).Decode(&requestBody); err != nil {
		return err
	}

	cartID, exists := requestBody["cart_id"].(int)
	if !exists {
		http.Error(res, "cart_id is required", http.StatusBadRequest)
		return fmt.Errorf("cart_id is required")
	}

	sign, exists := requestBody["sign"].(string)
	if !exists {
		http.Error(res, "cart_id is required", http.StatusBadRequest)
		return fmt.Errorf("cart_id is required")
	}

	err := s.store.Cancel_Checkout(cartID, sign)
	if err != nil {
		return err
	}

	res.WriteHeader(http.StatusOK)
	res.Write([]byte("Success"))
	return nil
}
