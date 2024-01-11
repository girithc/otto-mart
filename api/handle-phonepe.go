package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handlePhonePeCheckStatus(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.PhonePeCartIdStatus)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePeCheckStatus()")
		return err
	}

	return WriteJSON(res, http.StatusOK, nil)
}

func (s *Server) handlePhonePePaymentCallback(res http.ResponseWriter, req *http.Request) error {
	// Parse query parameters
	queryParams := req.URL.Query()
	cartIDStr := queryParams.Get("cart_id")
	sign := queryParams.Get("sign")

	// Convert cart_id from string to int
	cartID, err := strconv.Atoi(cartIDStr)
	if err != nil {
		fmt.Printf("Error converting cart_id to int: %v\n", err)
		return err
	}

	new_req := new(types.CallbackResponse)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePePaymentCallback()")
		return err
	}

	// Assuming you need to pass cart_id and sign to PhonePePaymentCallback
	_, err = s.store.PhonePePaymentCallback(cartID, sign, new_req.Response)
	if err != nil {
		fmt.Printf("Error inside PhonePePaymentCallback(): %v\n", err)
		return err
	}

	return nil
}

func (s *Server) handlePhonePePaymentInit(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.PhonePeCartId)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePePaymentInit()")
		return err
	}

	records, err := s.store.PhonePePaymentInit(new_req.CartId, new_req.Sign, new_req.MerchantTransactionID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
