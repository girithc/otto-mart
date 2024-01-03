package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Delivery_Partner_Login(res http.ResponseWriter, req *http.Request) error {
	// Preprocessing

	new_req := new(types.Create_Delivery_Partner)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Delivery_Partner_Login()")
		return err
	}

	new_user, err := types.New_Delivery_Partner(new_req.Phone, new_req.Name, new_req.Store_ID)
	if err != nil {
		return err
	}

	// Check if Delivery Partner Exists
	user, err := s.store.Get_Delivery_Partner_By_Phone(new_user.Phone)
	if err != nil {
		return err
	}

	// Delivery Partner
	if user == nil {
		fmt.Println("Delivery Partner Does Not Exist")

		user, err := s.store.Create_Delivery_Partner(new_req)
		if err != nil {
			return err
		}

		// Generate JWT token
		tokenString, err := generateJWT(user.Phone)
		if err != nil {
			return err
		}

		// Set the JWT token as a cookie
		expirationTime := time.Now().Add(1 * time.Hour)
		http.SetCookie(res, &http.Cookie{
			Name:    "token",
			Value:   tokenString,
			Expires: expirationTime,
		})

		return WriteJSON(res, http.StatusOK, user)
	} else { // Delivery Partner Exists
		fmt.Println("Delivery Partner Exists")

		// Generate JWT token
		tokenString, err := generateJWT(user.Phone)
		if err != nil {
			return err
		}

		// Set the JWT token as a cookie
		expirationTime := time.Now().Add(1 * time.Hour)
		http.SetCookie(res, &http.Cookie{
			Name:    "token",
			Value:   tokenString,
			Expires: expirationTime,
		})

		return WriteJSON(res, http.StatusOK, user)
	}
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

func (s *Server) HandlePostDeliveryPartnerLogin(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.DeliveryPartnerPhone)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleCheckAssignedOrder()")
		return err
	}

	// Check if Delivery Partner Exists
	user, err := s.store.Get_Delivery_Partner_By_Phone(new_req.Phone)
	if err != nil {
		return err
	}

	if user != nil {
		return WriteJSON(res, http.StatusOK, user)

	}

	new_user, err := s.store.DeliveryPartnerLogin(new_req.Phone)
	if err != nil {
		return err
	}
	return WriteJSON(res, http.StatusOK, new_user)

}
