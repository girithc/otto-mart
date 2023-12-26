package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) HandleCreateShelf(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered HandleCreateShelf")

	new_req := new(types.CreateShelf)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in HandleCreateShelf()")
		return err
	}

	items, err := s.store.CreateShelf(new_req.StoreId, new_req.Horizontal, new_req.Barcode, new_req.Vertical)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, items)
}

func (s *Server) HandleGetShelf(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered HandleGetShelf")

	// Get store_id from query parameters
	storeIDStr := req.URL.Query().Get("store_id")

	// Convert storeIDStr to an int
	storeID, err := strconv.Atoi(storeIDStr)
	if err != nil {
		// Handle the error if the conversion fails
		fmt.Println("Error converting store_id to integer:", err)
		return err
	}

	items, err := s.store.GetShelf(storeID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, items)
}
