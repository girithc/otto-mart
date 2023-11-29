package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Checkout_Cart(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered Handle_Checkout_Cart")
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

	if cart_id_exists {
		fmt.Println("Cart_id Exists")
		err := s.store.Checkout_Items(new_req.Cart_Id, new_req.Payment)
		if err != nil {
			return err
		}
	}

	return nil
}

func (s *Server) handlePostCheckoutLockItems(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered handlePostCheckoutLockItems")

	new_req := new(types.Checkout_Lock_Items)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePostCheckoutLockItems()")
		return err
	}

	_, err := s.store.GenMerchantUserId(new_req.Cart_Id)
	if err != nil {
		return err
	}

	areItemsLocked, err := s.store.LockStock(new_req.Cart_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, areItemsLocked)
}

func (s *Server) handlePostCheckoutPayment(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered handlePostCheckoutPayment")

	new_req := new(types.Checkout_Lock_Items)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePostCheckoutPayment()")
		return err
	}

	isPaid, err := s.store.PayStock(new_req.Cart_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, isPaid)
}
