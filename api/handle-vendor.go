package api

import (
	"encoding/json"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handleGetVendorList(res http.ResponseWriter, req *http.Request) error {
	vendorList, err := s.store.GetVendorList()
	if err != nil {
		return err
	}
	return WriteJSON(res, http.StatusOK, vendorList)
}

func (s *Server) handleCreateVendor(res http.ResponseWriter, req *http.Request) error {
	newReq := new(types.AddVendor)
	if err := json.NewDecoder(req.Body).Decode(newReq); err != nil {
		return err
	}

	vendor, err := s.store.AddVendor(newReq)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, vendor)
}

func (s *Server) handleEditVendorDetails(res http.ResponseWriter, req *http.Request) error {
	editReq := new(types.Vendor)
	if err := json.NewDecoder(req.Body).Decode(editReq); err != nil {
		return err
	}

	vendor, err := s.store.EditVendor(*editReq) // Pass the dereferenced value of editReq
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, vendor)
}
