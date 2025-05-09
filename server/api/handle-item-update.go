package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) HandleGetItemBarcode(res http.ResponseWriter, req *http.Request) error {
	new_req := &types.Barcode{}

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in HandleUpdateItemBarcode: %w", err)
	}

	// Create the new item using the provided CreateItem function
	item, err := s.store.GetItemFromBarcode(new_req.Barcode)
	if err != nil {
		return err
	}

	// Return the newly created item as a JSON response
	return WriteJSON(res, http.StatusOK, item)
}

func (s *Server) HandleUpdateItemBarcode(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered HandleUpdateItemBarcode")
	new_req := &types.Item_Barcode{}
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in HandleUpdateItemBarcode: %w", err)
	}

	// Create the new item using the provided CreateItem function
	item, err := s.store.AddBarcodeToItem(new_req.Barcode, new_req.ItemId)
	if err != nil {
		return err
	}

	if item {
		item_record, err := s.store.Get_Item_By_ID(new_req.ItemId)
		if err != nil {
			return err
		}
		return WriteJSON(res, http.StatusOK, item_record)
	}

	// Return the newly created item as a JSON response
	return WriteJSON(res, http.StatusOK, item)
}

func (s *Server) HandleUpdateItemAddStock(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered HandleUpdateItemAddStock")
	new_req := &types.ItemAddStock{}
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		return fmt.Errorf("error decoding request body in HandleUpdateItemBarcode: %w", err)
	}

	// Create the new item using the provided CreateItem function
	item, err := s.store.AddStockUpdateItem(new_req.AddStock, new_req.ItemId)
	if err != nil {
		return err
	}

	// Return the newly created item as a JSON response
	return WriteJSON(res, http.StatusOK, item)
}
