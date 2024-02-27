package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handleSendOtpPackerMSG91(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Customer)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleSendOtpMSG91")
		return err
	}

	result, err := s.store.SendOtpPackerMSG91(new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handleVerifyOtpPackerMSG91(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.MobileOtp)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleVerifyOtpMSG91")
		return err
	}

	result, err := s.store.VerifyOtpPackerMSG91(new_req.Phone, new_req.Otp, new_req.FCM)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) HandlePackerLogin(res http.ResponseWriter, req *http.Request) error {
	// Preprocessing

	new_req := new(types.PackerFCM)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in HandlePackerLogin()")
		return err
	}

	packer, err := s.store.GetPackerByPhone(new_req.Phone, new_req.FCM)
	if err != nil {
		return err
	}

	// Check if User Exists

	return WriteJSON(res, http.StatusOK, packer)
}

func (s *Server) handleManagerItemStoreComboBasic(res http.ResponseWriter, req *http.Request) error {
	item, err := s.store.ManagerItemStoreCombo()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, item)
}

func (s *Server) handleManagerAddNewItemBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.ItemBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleManagerAddNewItem")
		return err
	}

	result, err := s.store.ManagerAddNewItem(*new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}
