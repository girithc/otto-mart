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

func (s *Server) handleManagerUpdateItemBarcodeBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.ItemBarcodeBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleManagerUpdateItemBarcode")
		return err
	}

	result, err := s.store.ManagerUpdateItemBarcode(*new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handlePackerFindItemBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.FindItemBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePackerFindItemBasic")
		return err
	}

	result, err := s.store.PackerFindItem(*new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handleManagerCreateOrderBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.CreateOrderBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleManagerCreateOrderBasic")
		return err
	}

	// Fetch transaction details
	result, err := s.store.FetchCompletedTransactionDetailsAndCreateOrder(new_req.CartId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)

}

func (s *Server) handleManagerFCMBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.FCM)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleManagerFCMBasic")
		return err
	}

	result, err := s.store.ManagerSendFCM(new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handlePackerGetOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.GetOrderBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePackerCompleteOrderBasic")
		return err
	}

	result, err := s.store.PackerGetOrder(new_req.StoreId, new_req.OTP)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handlePackerCompleteOrderBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.CompleteOrderBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePackerCompleteOrderBasic")
		return err
	}

	result, err := s.store.PackerCompleteOrder(new_req.CartId, new_req.CustomerPhone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handlePackerLoadItemBasic(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.LoadItemBasic)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePackerLoadItemBasic")
		return err
	}

	result, err := s.store.PackerLoadItem(*new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) PackerCheckOrderToPack(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.PackerPhone)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in PackerCheckOrderToPack")
		return err
	}

	result, err := s.store.PackerCheckOrderToPack(new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}
