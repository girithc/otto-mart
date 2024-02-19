package api

import "net/http"

func (s *Server) handleGetVendorList(res http.ResponseWriter, req *http.Request) error {
	vendorList, err := s.store.GetVendorList()
	if err != nil {
		return err
	}
	return WriteJSON(res, http.StatusOK, vendorList)
}
