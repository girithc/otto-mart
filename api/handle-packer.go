package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) HandlePackerLogin(res http.ResponseWriter, req *http.Request) error {
	// Preprocessing

	new_req := new(types.Create_Customer)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in HandlePackerLogin()")
		return err
	}

	str := fmt.Sprintf("%d", new_req.Phone)
	new_user, err := s.store.CreatePacker(str)
	if err != nil {
		return err
	}

	// Check if User Exists

	return WriteJSON(res, http.StatusOK, new_user)
}
