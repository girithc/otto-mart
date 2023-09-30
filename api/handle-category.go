package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Category(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Create_Category)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in CreateCategory()")
		return err
	}

	new_category, err := types.New_Category(new_req.Name)
	if err != nil {
		return err
	}
	category, err := s.store.Create_Category(new_category)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, category)
}

func (s *Server) Handle_Get_Categories(res http.ResponseWriter, req *http.Request) error {
	// check if req has empty url param
	hlc_id := req.URL.Query().Get("id")

	// Check if URL Param is empty or 0
	if hlc_id == "" || hlc_id == "0" {
		categories, err := s.store.Get_Categories()
		if err != nil {
			return err
		}

		return WriteJSON(res, http.StatusOK, categories)
	} else {
		num, err := strconv.Atoi(hlc_id)
		if err != nil {
			return err
		}
		new_category_parent, err := types.New_Category_Parent_Id(num)
		if err != nil {
			return err
		}

		if new_category_parent.ID > 0 {

			categories, err := s.store.Get_Category_By_Parent_ID(new_category_parent.ID)
			if err != nil {
				return err
			}
			return WriteJSON(res, http.StatusOK, categories)

		}
	}
	return fmt.Errorf("end of function handle_get_categories")
}

func (s *Server) Handle_Update_Category(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Update_Category)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Category()")
		return err
	}

	category, err := s.store.Get_Category_By_ID(new_req.ID)
	if err != nil {
		return err
	}

	if len(new_req.Name) == 0 {
		new_req.Name = category.Name
	}

	updated_category, err := s.store.Update_Category(new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, updated_category)
}

func (s *Server) Handle_Delete_Category(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Delete_Category)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode Handle_Update_Category()")
		return err
	}

	if err := s.store.Delete_Category(new_req.ID); err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, map[string]int{"deleted": new_req.ID})
}
