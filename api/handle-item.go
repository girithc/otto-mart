package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Item(res http.ResponseWriter, req *http.Request) error {
	new_req := &types.Create_Item{}
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in handle_create_Item: %w", err)
	}

	// Convert Create_Item structure to Item structure using New_Item function
	itemStruct, err := types.New_Item(
		new_req.Name,
		new_req.MRP_Price,
		new_req.Discount,
		new_req.Store_Price,
		new_req.Category,
		new_req.Store, // Assuming a single store for simplicity
		new_req.Brand,
		new_req.Stock_Quantity,
		new_req.Image,
		new_req.Description,
		new_req.Quantity,
		new_req.Unit_Of_Quantity,
	)
	if err != nil {
		return fmt.Errorf("error converting create_item to Item: %w", err)
	}

	// Create the new item using the provided CreateItem function
	item, err := s.store.CreateItem(itemStruct)
	if err != nil {
		return err
	}

	// Return the newly created item as a JSON response
	return WriteJSON(res, http.StatusOK, item)
}

func (s *Server) Handle_Get_Items(res http.ResponseWriter, req *http.Request) error {
	category_id := req.URL.Query().Get("category_id")
	store_id := req.URL.Query().Get("store_id")

	if category_id == "" && store_id == "" {
		item_id := req.URL.Query().Get("item_id")
		if item_id == "" {
			barcode := req.URL.Query().Get("barcode")
			if barcode == "" {
				items, err := s.store.GetItems()
				if err != nil {
					return err
				}
				return WriteJSON(res, http.StatusOK, items)
			}

			// Create the new item using the provided CreateItem function
			item, err := s.store.GetItemFromBarcode(barcode)
			if err != nil {
				return err
			}

			// Return the newly created item as a JSON response
			return WriteJSON(res, http.StatusOK, item)
		}

		itemID, err := strconv.Atoi(item_id)
		if err != nil {
			return fmt.Errorf("invalid item_id provided: %w", err)
		}

		item, err := s.store.Get_Item_By_ID(itemID)
		if err != nil {
			return err
		}
		return WriteJSON(res, http.StatusOK, item)

	} else if category_id == "" {
		return fmt.Errorf("category_id is empty. Please provide category_id value")
	} else if store_id == "" {
		return fmt.Errorf("store_id is empty. Please provide store_id value")
	} else {
		categoryID, err := strconv.Atoi(category_id)
		if err != nil {
			return fmt.Errorf("invalid category_id provided: %w", err)
		}

		storeID, err := strconv.Atoi(store_id)
		if err != nil {
			return fmt.Errorf("invalid store_id provided: %w", err)
		}

		items, err := s.store.Get_Items_By_CategoryID_And_StoreID(categoryID, storeID)
		if err != nil {
			return err
		}
		return WriteJSON(res, http.StatusOK, items)
	}
}

func (s *Server) HandleAddStockToItem(res http.ResponseWriter, req *http.Request) error {
	items, err := s.store.AddStockToItem()
	if err != nil {
		return err
	}
	return WriteJSON(res, http.StatusOK, items)
}

func (s *Server) HandleGetItemAddByStore(res http.ResponseWriter, req *http.Request) error {
	print("Enter HandleGetItemAddByStore")
	new_req := new(types.GetItemAdd)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in HandleGetItemAddByStore: %w", err)
	}

	itemStockUpdate, err := s.store.GetItemAdd(new_req.Barcode, new_req.StoreId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, itemStockUpdate)
}

func (s *Server) HandleItemAddStockByStore(res http.ResponseWriter, req *http.Request) error {
	print("Enter HandleItemAddStockByStore")
	new_req := new(types.AddItemStockStore)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in HandleItemAddStockByStore: %w", err)
	}

	itemStockUpdate, err := s.store.AddStockToItemByStore(new_req.ItemId, new_req.StoreId, new_req.AddStock)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, itemStockUpdate)
}

func (s *Server) Handle_Update_Item(res http.ResponseWriter, req *http.Request) error {
	new_req := &types.Update_Item{}
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in handle_update_item: %w", err)
	}

	existingItem, err := s.store.Get_Item_By_ID(new_req.ID)
	if err != nil {
		return err
	}

	if new_req.Name == "" {
		new_req.Name = existingItem.Name
	}
	if new_req.MRP_Price == 0 {
		new_req.MRP_Price = existingItem.MRP_Price
	}
	if new_req.Stock_Quantity < 0 {
		new_req.Stock_Quantity = existingItem.Stock_Quantity
	}

	updated_item, err := s.store.Update_Item(new_req)
	if err != nil {
		return err
	}

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

func (s *Server) HandleItemAddQuick(res http.ResponseWriter, req *http.Request) error {
	print("Enter HandleItemAddStockByStore")
	new_req := new(types.ItemAddQuick)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in HandleItemAddStockByStore: %w", err)
	}

	itemStockUpdate, err := s.store.CreateItemAddQuick(*new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, itemStockUpdate)
}
