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

func (s *Server) handleGetCustomerPlacedOrder(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.SalesOrderRecent)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleOrdersByCartIdCustomerId()")
		return err
	}

	records, err := s.store.GetCustomerPlacedOrder(new_req.CustomerId, new_req.CartID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleOldestOrderByStore(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.SalesOrderStore)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleOrdersByCartIdCustomerId()")
		return err
	}

	records, err := s.store.GetOldestOrderForStore(new_req.StoreId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleReceivedOrderByStore(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.SalesOrderStore)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleOrdersByCartIdCustomerId()")
		return err
	}

	records, err := s.store.GetReceivedOrdersForStore(new_req.StoreId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleOrderItemsByStoreAndOrderId(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.SalesOrderStoreAndOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleOrdersByCartIdCustomerId()")
		return err
	}

	records, err := s.store.GetOrderItemsByStoreAndOrderId(new_req.OrderId, new_req.StoreId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) handleSalesOrderDetailsPOST(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.SalesOrderIDCustomerID)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode handleOrdersByCartIdCustomerId()")
		return err
	}

	records, err := s.store.GetSalesOrderDetails(new_req.SalesOrderID, new_req.CustomerID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) GetRecentSalesOrderByStore(res http.ResponseWriter, req *http.Request) error {
	print("Enter GetRecentSalesOrderByStore")
	new_req := new(types.RecentOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in GetRecentSalesOrderByStore()")
		return err
	}

	records, err := s.store.GetCombinedOrderDetails(new_req.StoreID, new_req.PackerPhone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) PackerFetchItem(res http.ResponseWriter, req *http.Request) error {
	print("Enter PackerFetchItem")
	new_req := new(types.AcceptOrderItem)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in PackerFetchItem()")
		return err
	}

	records, err := s.store.GetItemFromBarcodeInOrder(new_req.Barcode, new_req.SalesOrderID, new_req.PackerPhone)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) PackerPackItem(res http.ResponseWriter, req *http.Request) error {
	print("Enter PackerFetchItem")
	new_req := new(types.AcceptOrderItem)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in PackerPackItem()")
		return err
	}

	records, err := s.store.PackerPackItem(new_req.Barcode, new_req.PackerPhone, new_req.SalesOrderID, new_req.StoreId)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) PackerGetAllPackedItems(res http.ResponseWriter, req *http.Request) error {
	print("Enter PackerGetAllPackedItems")
	new_req := new(types.PackedOrderItem)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in PackerGetAllPackedItems()")
		return err
	}

	records, err := s.store.GetAllPackedItems(new_req.PackerPhone, new_req.SalesOrderID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) CancelPackSalesOrder(res http.ResponseWriter, req *http.Request) error {
	print("Enter CancelPackSalesOrder")
	new_req := new(types.CancelRecentOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in CancelPackSalesOrder()")
		return err
	}

	records, err := s.store.CancelPackOrder(new_req.StoreID, new_req.PackerPhone, new_req.OrderID)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}

func (s *Server) PackerAllocateSpace(res http.ResponseWriter, req *http.Request) error {
	print("Enter PackerAllocateSpace")
	new_req := new(types.SpaceOrder)
	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error Decode in PackerPackItem()")
		return err
	}

	records, err := s.store.PackerOrderAllocateSpace(new_req.Barcode, new_req.PackerPhone, new_req.SalesOrderID, new_req.StoreId, new_req.Image)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, records)
}
