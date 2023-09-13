package api

import "net/http"


func (s *Server) Handle_Get_All_Active_Shopping_Carts(res http.ResponseWriter, req *http.Request) error {

	carts, err := s.store.Get_All_Active_Shopping_Carts();
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, carts)
}