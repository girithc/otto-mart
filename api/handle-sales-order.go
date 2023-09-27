package api

import "net/http"


func (s *Server) Handle_Get_Sales_Orders (res http.ResponseWriter, req *http.Request) error {
	
	sales_orders, err := s.store.Get_All_Sales_Orders()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, sales_orders)
}