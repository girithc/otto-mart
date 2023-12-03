package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handlePhonePeCheckStatus(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.PhonePeCartIdStatus)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePeCheckStatus()")
		return err
	}

	records, err := s.store.PhonePeCheckStatus(new_req.CartId, new_req.StatusResult)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handlePhonePePaymentCallback(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.CallbackResponse)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePePaymentCallback()")
		return err
	}
	_, err := s.store.PhonePePaymentCallback(new_req.Response)
	if err != nil {
		fmt.Printf("Error inside PhonePePaymentCallback(): %v\n", err)
		return err
	}

	return nil
}

func (s *Server) handlePhonePePaymentComplete(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.PhonePeCartId)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePePaymentInit()")
		return err
	}

	records, err := s.store.PayStock(new_req.CartId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handlePhonePePaymentInit(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.PhonePeCartId)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePhonePePaymentInit()")
		return err
	}

	records, err := s.store.PhonePePaymentInit(new_req.CartId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
