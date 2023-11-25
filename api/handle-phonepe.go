package api

import (
	"net/http"
)

func (s *Server) handlePhonePePaymentInit(res http.ResponseWriter, req *http.Request) error {
	records, err := s.store.PhonePePaymentInit()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
