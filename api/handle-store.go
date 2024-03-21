package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Store(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Store)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	new_store, err := types.New_Store(new_req.Name, new_req.Address)
	if err != nil {
		return err
	}
	store, err := s.store.Create_Store(new_store)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, store)
}

func (s *Server) Handle_Get_Stores(res http.ResponseWriter, req *http.Request) error {
	stores, err := s.store.Get_Stores()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, stores)
}

func (s *Server) Handle_Update_Store(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Update_Store)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Store()")
		return err
	}

	store, err := s.store.Get_Store_By_ID(new_req.ID)
	if err != nil {
		return err
	}

	if len(new_req.Name) == 0 {
		new_req.Name = store.Name
	}
	if len(new_req.Address) == 0 {
		new_req.Address = store.Address
	}

	updated_store, err := s.store.Update_Store(new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, updated_store)
}

func (s *Server) Handle_Delete_Store(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Delete_Store)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Store()")
		return err
	}

	if err := s.store.Delete_Store(new_req.ID); err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, map[string]int{"deleted": new_req.ID})
}

func (s *Server) HandleGetStoreAddress(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.StoreId)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in HandleGetStoreAddress()")
		return err
	}

	address, err := s.store.GetStoreAddress(new_req.StoreId, new_req.AddressId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, address)
}
