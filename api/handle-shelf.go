package api

import (
	"encoding/json"
	"fmt"
	"net/http"

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
