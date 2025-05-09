package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) handleRemoveLockedQuantities(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Item_Store)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Delete_Item()")
		return err
	}

	records, err := s.store.RemoveLockQuantities(new_req.CartId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleUnlockLockQuantities(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Item_Store_Unlock)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Delete_Item()")
		return err
	}

	records, err := s.store.UnlockQuantities(new_req.CartId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
