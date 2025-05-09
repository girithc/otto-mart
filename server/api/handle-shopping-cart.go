package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Get_All_Active_Shopping_Carts(res http.ResponseWriter, req *http.Request) error {
	carts, err := s.store.Get_All_Active_Shopping_Carts()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, carts)
}

func (s *Server) Handle_Get_Shopping_Cart_By_Customer_Id(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Get_Shopping_Cart)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	cart, err := s.store.Get_Shopping_Cart_By_Customer_Id(new_req.Customer_Id, new_req.Active)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, cart)
}

func (s *Server) handleGetCustomerCartDetails(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Shopping_Cart_Details)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	cart, err := s.store.GetCustomerCart(new_req.Customer_Id, new_req.Cart_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, cart)
}

func (s *Server) handleGetCustomerCartSlots(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Shopping_Cart_Details)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	cart, err := s.store.GetCartSlots(new_req.Customer_Id, new_req.Cart_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, cart)
}

func (s *Server) handleAssignCustomerCartSlots(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.AssignSlot)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	cart, err := s.store.AssignCartSlot(new_req.Customer_Id, new_req.Cart_Id, new_req.Slot_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, cart)
}

func (s *Server) handleApplyPromo(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.ApplyPromo)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	err := s.store.ApplyPromo(new_req.Promo, new_req.CartId)
	if err != nil {
		return err
	}

	cartItemList, err := s.store.Get_Items_List_From_Cart_Items_By_Cart_Id(new_req.CartId)
	if err != nil {
		return err
	}
	fmt.Println("cartItemList", cartItemList)

	cart, err := s.store.GetCartDetails(new_req.CartId)
	if err != nil {
		return err
	}
	print("updated cartDetails, ", cart)

	cartResponse := types.CartItemResponse{
		CartDetails:   cart,
		CartItemsList: cartItemList,
	}

	return WriteJSON(res, http.StatusOK, cartResponse)
}

func (s *Server) handleResetPrice(res http.ResponseWriter, req *http.Request) error {
	err := s.store.ResetPrices()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, true)
}
