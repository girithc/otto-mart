package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Address(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Address)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Create_Address()")
		return WriteJSON(res, http.StatusBadRequest, err)
	}

	addr, err := s.store.Create_Address(new_req)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, err)
	}

	return WriteJSON(res, http.StatusOK, addr)
}

func (s *Server) Handle_Get_Address_By_Customer_Id(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Address_Customer_Id)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Get_Address_By_Customer_Id()")
		return err
	}

	addr, err := s.store.Get_Addresses_By_Customer_Id(new_req.Customer_Id, true)
	if err != nil {
		return err
	}

	addrs, err := s.store.Get_Addresses_By_Customer_Id(new_req.Customer_Id, false)
	if err != nil {
		return err
	}

	addr_list := append(addr, addrs...)

	return WriteJSON(res, http.StatusOK, addr_list)
}

func (s *Server) handleGetDefaultAddress(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Address_Customer_Id)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Get_Address_By_Customer_Id()")
		return err
	}

	addrs, err := s.store.Get_Addresses_By_Customer_Id(new_req.Customer_Id, true)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, addrs)
}

func (s *Server) handleMakeDefaultAddress(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.MakeDefaultAddress)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Get_Address_By_Customer_Id()")
		return err
	}

	addrs, err := s.store.MakeDefaultAddress(new_req.Customer_Id, new_req.Address_Id, true)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, addrs)
}

func (s *Server) handleDeliverToAddress(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliverToAddress)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Get_Address_By_Customer_Id()")
		return err
	}

	addrs, err := s.store.DeliverToAddress(new_req.Customer_Id, new_req.Address_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, addrs)
}

func (s *Server) handleDeleteAddress(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Delete_Address)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleDeleteAddress()")
		return err
	}

	print("Customer ID: ", new_req.Customer_Id, " Address_ID: ", new_req.Address_Id)

	addrs, err := s.store.Delete_Address(new_req.Customer_Id, new_req.Address_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, addrs)
}
