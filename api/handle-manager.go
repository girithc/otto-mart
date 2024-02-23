package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handleSendOtpManagerMSG91(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Customer)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleSendOtpMSG91")
		return err
	}

	result, err := s.store.SendOtpManagerMSG91(new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handleVerifyOtpManagerMSG91(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.MobileOtp)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleVerifyOtpMSG91")
		return err
	}

	result, err := s.store.VerifyOtpManagerMSG91(new_req.Phone, new_req.Otp, new_req.FCM)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) HandleManagerLogin(res http.ResponseWriter, req *http.Request) error {
	// Preprocessing

	new_req := new(types.ManagerFCM)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in HandleManagerLogin()")
		return err
	}

	packer, err := s.store.GetManagerByPhone(new_req.Phone, new_req.FCM)
	if err != nil {
		return err
	}

	// Check if User Exists

	return WriteJSON(res, http.StatusOK, packer)
}
