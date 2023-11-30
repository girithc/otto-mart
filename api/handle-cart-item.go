package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Add_Cart_Item(res http.ResponseWriter, req *http.Request, requestBodyReader *bytes.Reader) error {
	// Data Extraction
	new_req := new(types.Create_Cart_Item)
	if err := json.NewDecoder(requestBodyReader).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Add_Cart_item()", err)
		return err
	}

	cart, err := s.store.Add_Cart_Item(new_req.CartId, new_req.ItemId, new_req.Quantity)
	if err != nil {
		return err
	}

	cartItemList, err := s.store.Get_Items_List_From_Cart_Items_By_Cart_Id(new_req.CartId)
	if err != nil {
		return err
	}

	cartResponse := types.CartItemResponse{
		CartDetails:   cart,
		CartItemsList: cartItemList,
	}

	return WriteJSON(res, http.StatusOK, cartResponse)
}

func (s *Server) Handle_Delete_Cart_item(res http.ResponseWriter, req *http.Request) error {
	return nil
}

func (s *Server) Handle_Get_All_Cart_Items(res http.ResponseWriter, req *http.Request, requestBodyReader *bytes.Reader) error {
	new_req := new(types.Get_Cart_Items)
	if err := json.NewDecoder(requestBodyReader).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Add_Cart_item()", err)
		return err
	}

	cart_id_exists, err := s.store.DoesCartExist(new_req.CartId)
	if err != nil {
		return err
	}
	if cart_id_exists {
		cart_items, err := s.store.Get_Cart_Items_By_Cart_Id(new_req.CartId)
		if err != nil {
			return err
		}

		return WriteJSON(res, http.StatusOK, cart_items)
	}

	return nil
}

func (s *Server) Handle_Get_Item_List_From_Cart_Item(res http.ResponseWriter, req *http.Request, requestBodyReader *bytes.Reader) error {
	new_req := new(types.Get_Cart_Items_Item_List)
	if err := json.NewDecoder(requestBodyReader).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Get_Item_List_From_Cart_Item()", err)
		return err
	}

	cart_id_exists, err := s.store.DoesCartExist(new_req.CartId)
	if err != nil {
		return err
	}
	if cart_id_exists {
		if new_req.Items {
			cart_items, err := s.store.Get_Items_List_From_Cart_Items_By_Cart_Id(new_req.CartId)
			if err != nil {
				return err
			}

			return WriteJSON(res, http.StatusOK, cart_items)
		}
	}

	return nil
}

func (s *Server) Handle_Get_Item_List_From_Cart_Item_By_Customer_Id(res http.ResponseWriter, req *http.Request, requestBodyReader *bytes.Reader) error {
	new_req := new(types.Cart_Item_Customer_Id)
	if err := json.NewDecoder(requestBodyReader).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Get_Item_List_From_Cart_Item_By_Customer_Id()", err)
		return err
	}

	cart_items, err := s.store.Get_Items_List_From_Active_Cart_By_Customer_Id(new_req.Customer_Id)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, cart_items)
}
