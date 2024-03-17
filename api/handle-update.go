package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) HandleNeedToUpdate(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Inside HandleNeedToUpdate")
	new_req := new(types.UpdateAppInput)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handleNeedToUpdate")
		return err
	}

	result, err := s.store.NeedToUpdate(new_req)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, result)
}
