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
	// Check if cart_id exists
	cart_id_exists, err := s.store.DoesCartExist(new_req.CartId)
	if err != nil {
		return err
	}
	// If Exists
	if cart_id_exists {
		// Check if item_id exists in cart_id
		item_id_exists, err := s.store.DoesItemExist(new_req.CartId, new_req.ItemId)
		if err != nil {
			return err
		}

		item, err := s.store.Get_Item_By_ID(new_req.ItemId)
		if err != nil {
			return err
		}

		// If exists add quantity +1 to the same record
		if item_id_exists {
			// Check if Item is in stock
			item_is_in_stock, err := s.store.IsItemInStock(item.Stock_Quantity, item.ID, new_req.CartId, new_req.Quantity)
			if err != nil {
				return err
			}

			if item_is_in_stock {
				_, err := s.store.Update_Cart_Item_Quantity(new_req.CartId, new_req.ItemId, new_req.Quantity)
				if err != nil {
					return err
				}

				cart_item_list, err := s.store.Get_Items_List_From_Cart_Items_By_Cart_Id(new_req.CartId)
				if err != nil {
					return err
				}

				return WriteJSON(res, http.StatusOK, cart_item_list)
			} else {
				error_message := new(types.Error_Message)
				error_message.Message = "Out Of Stock - Item In Cart"
				return WriteJSON(res, http.StatusNotAcceptable, error_message)
			}

		} else { // Else add cart_item record with quantity +1

			item_is_in_stock, err := s.store.IsItemInStock(item.Stock_Quantity, item.ID, new_req.CartId, new_req.Quantity)
			if err != nil {
				return err
			}

			if item_is_in_stock {
				_, err := s.store.Add_Cart_Item(new_req.CartId, new_req.ItemId, new_req.Quantity)
				if err != nil {
					return err
				}

				cart_item_list, err := s.store.Get_Items_List_From_Cart_Items_By_Cart_Id(new_req.CartId)
				if err != nil {
					return err
				}

				return WriteJSON(res, http.StatusOK, cart_item_list)
			} else {
				error_message := new(types.Error_Message)
				error_message.Message = "Out Of Stock - No Cart"
				return WriteJSON(res, http.StatusNotAcceptable, error_message)
			}
		}
	}

	// Else Throw Error

	return fmt.Errorf("invalid cart id")
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
