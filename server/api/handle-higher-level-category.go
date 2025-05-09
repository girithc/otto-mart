package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Higher_Level_Category(res http.ResponseWriter, req *http.Request) error {
	_ = new(types.Create_Higher_Level_Category)

	return nil
}

func (s *Server) Handle_Get_Higher_Level_Categories(res http.ResponseWriter, req *http.Request) error {
	higher_level_categories, err := s.store.Get_Higher_Level_Categories()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, higher_level_categories)
}

func (s *Server) Handle_Update_Higher_Level_Category(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Update_Higher_Level_Category)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Higher_Level_Category()")
		return err
	}

	higher_level_category, err := s.store.Get_Higher_Level_Category_By_ID(new_req.ID)
	if err != nil {
		return err
	}

	if len(new_req.Name) == 0 {
		new_req.Name = higher_level_category.Name
	}

	updated_higher_level_category, err := s.store.Update_Higher_Level_Category(new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, updated_higher_level_category)
}

func (s *Server) Handle_Delete_Higher_Level_Category(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Delete_Higher_Level_Category)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Higher_Level_Category()")
		return err
	}

	if err := s.store.Delete_Higher_Level_Category(new_req.ID); err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, map[string]int{"deleted": new_req.ID})
}
