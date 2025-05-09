package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Category_Higher_Level_Mapping(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Category_Higher_Level_Mapping)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Create New_Category_Higher_Level_Mapping()")
		return err
	}

	fmt.Println(" Create chlm checkpoint 1")

	new_category_higher_level_mapping, err := types.New_Category_Higher_Level_Mapping(new_req.Higher_Level_Category_ID, new_req.Category_ID)
	if err != nil {
		return err
	}

	fmt.Println(" Create chlm checkpoint 2")

	category_higher_level_mapping, err := s.store.Create_Category_Higher_Level_Mapping(new_category_higher_level_mapping)
	if err != nil {
		return err
	}

	fmt.Println(" Create chlm checkpoint 3")

	return WriteJSON(res, http.StatusOK, category_higher_level_mapping)
}

func (s *Server) Handle_Get_Category_Higher_Level_Mappings(res http.ResponseWriter, req *http.Request) error {
	category_higher_level_mappings, err := s.store.Get_Category_Higher_Level_Mappings()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, category_higher_level_mappings)
}

func (s *Server) Handle_Update_Category_Higher_Level_Mapping(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Update_Category_Higher_Level_Mapping)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Category()")
		return err
	}

	category_higher_level_mapping, err := s.store.Get_Category_Higher_Level_Mapping_By_ID(new_req.ID)
	if err != nil {
		return err
	}

	if new_req.Higher_Level_Category_ID == 0 {
		new_req.Higher_Level_Category_ID = category_higher_level_mapping.Higher_Level_Category_ID
	} else {
		_, err := s.store.Get_Higher_Level_Category_By_ID(new_req.Higher_Level_Category_ID)
		if err != nil {
			return err
		}
	}
	if new_req.Category_ID == 0 {
		new_req.Category_ID = category_higher_level_mapping.Category_ID
	} else {
		_, err := s.store.Get_Category_By_ID(new_req.Category_ID)
		if err != nil {
			return err
		}
	}

	updated_category_higher_level_mapping, err := s.store.Update_Category_Higher_Level_Mapping(new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, updated_category_higher_level_mapping)
}

func (s *Server) Handle_Delete_Category_Higher_Level_Mapping(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Delete_Category_Higher_Level_Mapping)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Category_Higher_Level_Mapping()")
		return err
	}

	if err := s.store.Delete_Category_Higher_Level_Mapping(new_req.ID); err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, map[string]int{"deleted": new_req.ID})
}
