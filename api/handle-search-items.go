package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Post_Search_Items(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered Handle_Post_Search_Items")

	new_req := new(types.Search_Item)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Create_Item()")
		return err
	}

	items, err := s.store.Search_Items(new_req.Name)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, items)
}
