package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Create_Brand(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered Handle_Create_Brand")

	new_req := new(types.Create_Brand)

	fmt.Println("Name : ", new_req.Name)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in Handle_Create_Item()")
		return err
	}

	new_brand, err := types.New_Brand(new_req.Name)
	if err != nil {
		return err
	}

	brand, err := s.store.CreateBrand(new_brand)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, brand)
}
