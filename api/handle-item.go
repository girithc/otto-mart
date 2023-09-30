package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Item(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered Handle_Get_Items")

	new_req := new(types.Create_Item)

	fmt.Println("Name : ", new_req.Name)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Create_Item()")
		return err
	}

	new_item, err := types.New_Item(new_req.Name, new_req.Price, new_req.Category_ID, new_req.Store_ID, new_req.Stock_Quantity, new_req.Image)
	if err != nil {
		return err
	}
	item, err := s.store.Create_Item(new_item)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, item)
}

func (s *Server) Handle_Get_Items(res http.ResponseWriter, req *http.Request) error {
	// check if req has empty body
	category_id := req.URL.Query().Get("category_id")
	store_id := req.URL.Query().Get("store_id")

	// Check if the Content-Length header is empty or 0
	if (category_id == "" || category_id == "0") && (store_id == "" || store_id == "0") {
		fmt.Println("Entered No Category_id and Store_id")
		item_id := req.URL.Query().Get("item_id")

		if item_id == "" || item_id == "0" {
			items, err := s.store.Get_Items()
			if err != nil {
				return err
			}

			return WriteJSON(res, http.StatusOK, items)
		}

		itemID, err := strconv.Atoi(item_id)
		if err != nil {
			return err
		}

		items, err := s.store.Get_Item_By_ID(itemID)
		if err != nil {
			return err
		}
		return WriteJSON(res, http.StatusOK, items)

	} else if category_id == "" || category_id == "0" {
		return fmt.Errorf("category_id is empty. Please provide category_id value")
	} else if store_id == "" || store_id == "0" {
		return fmt.Errorf("store_id is empty. Please provide store_id value")
	} else {
		fmt.Println("Category and Store ID present")
		categoryID, err := strconv.Atoi(category_id)
		if err != nil {
			return err
		}

		storeID, err := strconv.Atoi(store_id)
		if err != nil {
			return err
		}

		items, err := s.store.Get_Items_By_CategoryID_And_StoreID(categoryID, storeID)
		if err != nil {
			return err
		}
		return WriteJSON(res, http.StatusOK, items)
	}
}

func (s *Server) Handle_Update_Item(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Update_Item)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Item()")
		return err
	}

	fmt.Println("Updated Id: ", new_req.ID)
	fmt.Println("Updated Name: ", new_req.Name)
	fmt.Println("Updated Price: ", new_req.Price)
	fmt.Println("Updated Stock Quantity: ", new_req.Stock_Quantity)
	fmt.Println("Updated Category Id: ", new_req.Category_ID)

	item, err := s.store.Get_Item_By_ID(new_req.ID)
	if err != nil {
		return err
	}

	fmt.Println("Valid Record Change Requested ", item)

	if len(new_req.Name) == 0 {
		new_req.Name = item.Name
	}
	if new_req.Price == 0 {
		new_req.Price = item.Price
	}
	if new_req.Stock_Quantity < 0 {
		new_req.Stock_Quantity = item.Stock_Quantity
	}
	if new_req.Category_ID == 0 {
		new_req.Category_ID = item.Category_ID
	}
	if len(new_req.Image) == 0 {
		new_req.Image = item.Image
	}

	updated_item, err := s.store.Update_Item(new_req)
	if err != nil {
		return err
	}

	fmt.Println("Record Change Completed", item)

	return WriteJSON(res, http.StatusOK, updated_item)
}

func (s *Server) Handle_Delete_Item(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Delete_Item)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Delete_Item()")
		return err
	}

	if err := s.store.Delete_Item(new_req.ID); err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, map[string]int{"deleted": new_req.ID})
}
