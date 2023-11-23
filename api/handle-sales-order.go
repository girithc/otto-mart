package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) Handle_Get_Sales_Orders(res http.ResponseWriter, req *http.Request) error {
	sales_orders, err := s.store.Get_All_Sales_Orders()
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, sales_orders)
}

func (s *Server) handleGetOrdersByDeliveryPartnerId(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Sales_Order_Delivery_Partner)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleGetAssignedOrders()")
		return err
	}

	records, err := s.store.GetOrdersByDeliveryPartner(new_req.DeliveryPartnerId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleGetOrdersByCustomerId(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.Sales_Order_Customer)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleGetAssignedOrders()")
		return err
	}

	records, err := s.store.GetOrdersByCustomerId(new_req.CustomerId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleOrdersByCartIdCustomerId(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.SalesOrderRecent)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleOrdersByCartIdCustomerId()")
		return err
	}

	records, err := s.store.GetRecentSalesOrderByCustomerId(new_req.CustomerId, 1, new_req.CartID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
