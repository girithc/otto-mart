package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

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

func (s *Server) handlePhonePePaymentInit(res http.ResponseWriter, req *http.Request) error {
	records, err := s.store.PhonePePaymentInit()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
