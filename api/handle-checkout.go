package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

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
