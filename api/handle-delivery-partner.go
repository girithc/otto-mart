package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handleSendOtpDeliveryPartnerMSG91(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Customer)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleSendOtpMSG91")
		return err
	}

	result, err := s.store.SendOtpDeliveryPartnerMSG91(new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) handleVerifyOtpDeliveryPartnerMSG91(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.MobileOtp)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleVerifyOtpMSG91")
		return err
	}

	result, err := s.store.VerifyOtpDeliveryPartnerMSG91(new_req.Phone, new_req.Otp, new_req.FCM)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}

func (s *Server) Handle_Delivery_Partner_FCM_Token(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.FCM_Token_Delivery_Partner)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Delivery_Partner_FCM_Token()")
		return err
	}

	// Check if Delivery Partner Exists
	_, err := s.store.Get_Delivery_Partner_By_Phone(new_req.Phone)
	if err != nil {
		return err
	}

	delivery_partner, err := s.store.Update_FCM_Token_Delivery_Partner(new_req.Phone, new_req.Fcm_Token)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, delivery_partner)
}

func (s *Server) Handle_Get_Delivery_Partners(res http.ResponseWriter, req *http.Request) error {
	customers, err := s.store.Get_All_Delivery_Partners()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, customers)
}

func (s *Server) handleCheckAssignedOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerPhone)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleCheckAssignedOrder()")
		return err
	}

	order, err := s.store.GetFirstAssignedOrder(new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerAcceptOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerAcceptOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerAcceptOrder()")
		return err
	}

	order, err := s.store.DeliveryPartnerAcceptOrder(new_req.Phone, new_req.SalesOrderId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerGetAssignedOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerStore)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerGetAssignedOrder()")
		return err
	}

	order, err := s.store.GetAssignedOrder(new_req.StoreId, new_req.Phone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerPickupOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerAcceptOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerPickupOrder()")
		return err
	}

	order, err := s.store.DeliveryPartnerPickupOrder(new_req.Phone, new_req.SalesOrderId)
	if err != nil {
		if osErr, ok := err.(*OrderStatusError); ok {
			// Handle the specific OrderStatusError
			return WriteJSON(res, http.StatusLocked, map[string]string{"error": osErr.Error()})
		}
		// Handle other types of errors
		return WriteJSON(res, http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	// Check if order is nil and err is nil, indicating no order changed
	if order == nil && err == nil {
		return WriteJSON(res, http.StatusNotModified, map[string]string{"message": "No order changed"})
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerArriveDestination(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerAcceptOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerArriveDestination()")
		return err
	}

	order, err := s.store.DeliveryPartnerArriveDestination(new_req.Phone, new_req.SalesOrderId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerGoDeliverOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerAcceptOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerGoDeliverOrder()")
		return err
	}

	order, err := s.store.DeliveryPartnerGoDeliverOrder(new_req.Phone, new_req.SalesOrderId)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, order)
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerDispatchOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerDispatchOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerDispatchOrder()")
		return err
	}

	order, err := s.store.DeliveryPartnerDispatchOrder(new_req.Phone, new_req.SalesOrderId)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, order)
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) PackerDispatchOrderHistory(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerDispatchOrderHistory)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerDispatchOrder()")
		return err
	}

	order, err := s.store.PackerDispatchOrderHistory(new_req.StoreId)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, order)
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerArrive(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerArriveOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerArrive()")
		return err
	}

	order, err := s.store.DeliveryPartnerArrive(new_req.Phone, new_req.SalesOrderId, new_req.Status)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, err)
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerCompleteOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DPCompleteOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerCompleteOrder()")
		return err
	}

	order, err := s.store.DeliveryPartnerCompleteOrderDelivery(new_req.Phone, new_req.SalesOrderId, new_req.AmountCollected)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, err)
	}

	return WriteJSON(res, http.StatusOK, order)
}

func (s *Server) DeliveryPartnerGetOrderDetails(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerAcceptOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in DeliveryPartnerGetOrderDetails()")
		return err
	}

	order, err := s.store.DeliveryPartnerGetOrderDetails(new_req.Phone, new_req.SalesOrderId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, order)
}

type OrderStatusError struct {
	Status string
}

func (e *OrderStatusError) Error() string {
	return fmt.Sprintf("order status: %s", e.Status)
}

func (s *Server) HandlePostDeliveryPartnerLogin(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPhoneFCM)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleCheckAssignedOrder()")
		return err
	}

	// Check if Delivery Partner Exists
	user, err := s.store.GetDeliveryPartnerByPhone(new_req.Phone, new_req.FCM)
	if err != nil {
		return err
	}

	if user != nil {
		return WriteJSON(res, http.StatusOK, user)
	}

	return WriteJSON(res, http.StatusOK, nil)
}
