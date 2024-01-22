package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
)

type HandlerFunc func(http.ResponseWriter, *http.Request) error

func (s *Server) goRoutineWrapper(handler HandlerFunc, res http.ResponseWriter, req *http.Request) error {
	resultChan := make(chan error, 1) // Create a channel to capture the result

	// Start a new Go routine to handle the task
	go func() {
		err := handler(res, req)
		resultChan <- err // Send the result error to the channel
	}()

	// Wait for the result from the Go routine and return it
	return <-resultChan
}

func (s *Server) handleCustomer(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cusromer")
		return s.goRoutineWrapper(s.HandleVerifyCustomerLogin, res, req)

	} else if req.Method == "GET" {
		print_path("GET", "customer")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		// Start a new Go routine to handle the task
		go func() {
			err := s.HandleGetCustomers(res, req)
			resultChan <- err // Send the result error to the channel
		}()

		// Wait for the result from the Go routine and return it
		return <-resultChan
	}

	return nil
}

func (s *Server) handleLoginCustomer(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "customer-login")
		return s.goRoutineWrapper(s.HandleCustomerLogin, res, req)
	}
	return nil
}

func (s *Server) handleLoginPacker(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-login")
		return s.goRoutineWrapper(s.HandlePackerLogin, res, req)
	}

	return nil
}

func (s *Server) handleShoppingCart(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "shopping_cart")
		return s.goRoutineWrapper(s.Handle_Get_All_Active_Shopping_Carts, res, req)

	} else if req.Method == "POST" {
		print_path("POST", "shopping_cart")
		return s.goRoutineWrapper(s.Handle_Get_Shopping_Cart_By_Customer_Id, res, req)
	}

	return nil
}

func (s *Server) handleCartItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cart-item")

		var requestBody map[string]interface{}
		decoder := json.NewDecoder(req.Body)
		if err := decoder.Decode(&requestBody); err != nil {
			// Handle error
			http.Error(res, "Failed to parse request body", http.StatusBadRequest)
			return err
		}

		if _, cartOk := requestBody["cart_id"].(float64); cartOk {
			if _, itemOk := requestBody["item_id"].(float64); itemOk {
				requestBodyBytes, _ := json.Marshal(requestBody)
				requestBodyReader := bytes.NewReader(requestBodyBytes)

				return s.Handle_Add_Cart_Item(res, req, requestBodyReader)
			} else if itemList, itemListOk := requestBody["items"].(bool); itemListOk {

				requestBodyBytes, _ := json.Marshal(requestBody)
				requestBodyReader := bytes.NewReader(requestBodyBytes)

				if itemList {
					return s.Handle_Get_Item_List_From_Cart_Item(res, req, requestBodyReader)
				} else {
					return s.Handle_Get_All_Cart_Items(res, req, requestBodyReader)
				}

			}
		} else if _, customerOk := requestBody["customer_id"].(float64); customerOk {

			// Create a new reader from the decoded data
			requestBodyBytes, _ := json.Marshal(requestBody)
			requestBodyReader := bytes.NewReader(requestBodyBytes)

			// Pass the new reader to Handle_Add_Cart_Item
			return s.Handle_Get_Item_List_From_Cart_Item_By_Customer_Id(res, req, requestBodyReader)
		}

	} else if req.Method == "DELETE" {
		print_path("DELETE", "cart-item")
		return s.goRoutineWrapper(s.Handle_Delete_Cart_item, res, req)
		// return s.Handle_Delete_Cart_item(res, req)
	} else if req.Method == "GET" {
		print_path("GET", "cart-item")
	}

	return nil
}

func (s *Server) handleStoreClient(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		pincode := req.URL.Query().Get("pincode")
		fmt.Println("We deliver to Area =>", pincode)
	}

	return nil
}

func (s *Server) handleStoreManager(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		fmt.Println("[GET] - Store(s)")
		return s.goRoutineWrapper(s.Handle_Get_Stores, res, req)
	} else if req.Method == "POST" {
		fmt.Println("[POST] - Store")
		return s.goRoutineWrapper(s.Handle_Create_Store, res, req)
	} else if req.Method == "PUT" {
		fmt.Println("[PUT] - Store")
		return s.goRoutineWrapper(s.Handle_Update_Store, res, req)
	} else if req.Method == "DELETE" {
		fmt.Println("[DELETE] - Store")
		return s.goRoutineWrapper(s.Handle_Delete_Store, res, req)
	}

	return fmt.Errorf("no matching path")
}

// Higher Level Category

func (s *Server) handleHigherLevelCategory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "higher_level_category")

		return s.goRoutineWrapper(s.Handle_Get_Higher_Level_Categories, res, req)

	} else if req.Method == "POST" {
		return s.goRoutineWrapper(s.Handle_Create_Higher_Level_Category, res, req)
	} else if req.Method == "PUT" {
		print_path("PUT", "higher_level_category")
		return s.goRoutineWrapper(s.Handle_Update_Higher_Level_Category, res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "higher_level_category")
		return s.goRoutineWrapper(s.Handle_Delete_Higher_Level_Category, res, req)
	}

	return nil
}

// Category
func (s *Server) handleCategory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "category")

		return s.goRoutineWrapper(s.Handle_Get_Categories, res, req)

	} else if req.Method == "POST" {
		print_path("POST", "category")

		return s.goRoutineWrapper(s.Handle_Create_Category, res, req)

	} else if req.Method == "PUT" {
		print_path("PUT", "category")
		return s.goRoutineWrapper(s.Handle_Update_Category, res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "category")
		return s.goRoutineWrapper(s.Handle_Delete_Category, res, req)
	}

	fmt.Println("Returning Nil")
	return nil
}

func (s *Server) handleGetCategory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("[GET]", "get-category")
		return s.goRoutineWrapper(s.HandleGetCategoryList, res, req)
	}
	return nil
}

func (s *Server) handleGetBrand(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("[GET]", "get-brand")
		return s.goRoutineWrapper(s.HandleGetBrandList, res, req)
	}
	return nil
}

// Category Higher Level Mapping
func (s *Server) handleCategoryHigherLevelMapping(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {

		print_path("GET", "category_higher_level_mapping")
		return s.goRoutineWrapper(s.Handle_Get_Category_Higher_Level_Mappings, res, req)

	} else if req.Method == "POST" {

		print_path("POST", "category_higher_level_mapping")
		return s.goRoutineWrapper(s.Handle_Create_Category_Higher_Level_Mapping, res, req)

	} else if req.Method == "PUT" {

		print_path("PUT", "category_higher_level_mapping")
		return s.goRoutineWrapper(s.Handle_Update_Category_Higher_Level_Mapping, res, req)

	} else if req.Method == "DELETE" {

		print_path("DELETE", "category_higher_level_mapping")
		return s.goRoutineWrapper(s.Handle_Delete_Category_Higher_Level_Mapping, res, req)

	}

	return nil
}

func (s *Server) handleItemStore(res http.ResponseWriter, req *http.Request) error {
	// add address or get address by customer id
	if req.Method == "POST" {
		print_path("POST", "item_store")
		// Check the content of the request body to determine which handler to invoke
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		// Check if only 'customer_id' is present in the request body
		if _, exists := requestBody["cart_id"]; exists {
			if len(requestBody) == 1 {
				return s.goRoutineWrapper(s.handleRemoveLockedQuantities, res, newReq)
			} else if len(requestBody) == 2 {
				return s.goRoutineWrapper(s.handleUnlockLockQuantities, res, newReq)
			}
		}
	}

	return nil
}

func (s *Server) handleItemUpdate(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item_update")

		// Check the content of the request body to determine which handler to invoke
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		// Check if only 'customer_id' is present in the request body

		if len(requestBody) == 2 { // is default
			if _, barcodeOk := requestBody["barcode"].(string); barcodeOk {
				return s.goRoutineWrapper(s.HandleUpdateItemBarcode, res, newReq)
			} else if _, addStockOk := requestBody["add_stock"].(float64); addStockOk {
				return s.goRoutineWrapper(s.HandleUpdateItemAddStock, res, newReq)
			}
		}
	}

	return nil
}

func (s *Server) handleItemAddStock(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item_add_stock")

		// Check the content of the request body to determine which handler to invoke
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}
		// Check if only 'customer_id' is present in the request body

		if len(requestBody) == 3 { // is default
			if _, addStockOk := requestBody["add_stock"].(float64); addStockOk {
				if _, itemIdOk := requestBody["item_id"].(float64); itemIdOk {
					if _, storeIdOk := requestBody["store_id"].(float64); storeIdOk {
						return s.goRoutineWrapper(s.HandleItemAddStockByStore, res, newReq)
					}
				}
			}
		} else if len(requestBody) == 2 {
			if _, barcodeOk := requestBody["barcode"].(string); barcodeOk {
				if _, storeIdOk := requestBody["store_id"].(float64); storeIdOk {
					return s.goRoutineWrapper(s.HandleGetItemAddByStore, res, newReq)
				}
			}
		}

	}
	return nil
}

// Item
func (s *Server) handleItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "item")
		return s.goRoutineWrapper(s.Handle_Get_Items, res, req)

	} else if req.Method == "POST" {
		print_path("POST", "item_store")

		// Check the content of the request body to determine which handler to invoke
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}
		// Check if only 'customer_id' is present in the request body

		if len(requestBody) == 1 {
			return s.goRoutineWrapper(s.HandleAddStockToItem, res, newReq)
		} else { // is default
			return s.goRoutineWrapper(s.Handle_Create_Item, res, newReq)
		}

	} else if req.Method == "PUT" {
		print_path("PUT", "item")
		return s.goRoutineWrapper(s.Handle_Update_Item, res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "item")
		return s.goRoutineWrapper(s.Handle_Delete_Item, res, req)
	}

	return nil
}

func (s *Server) handleSearchItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "search item")

		return s.goRoutineWrapper(s.Handle_Post_Search_Items, res, req)

	}

	return nil
}

func (s *Server) handleItemAddQuick(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item-add-quick")
		return s.goRoutineWrapper(s.HandleItemAddQuick, res, req)
	}

	return nil
}

func (s *Server) handlePackerPackOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-pack")
		return s.goRoutineWrapper(s.GetRecentSalesOrderByStore, res, req)
	}
	return nil
}

func (s *Server) handlePackerFetchItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-fetch-item")
		return s.goRoutineWrapper(s.PackerFetchItem, res, req)
	}
	return nil
}

func (s *Server) handlePackerGetAllItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-get-all-items")
		return s.goRoutineWrapper(s.PackerGetAllPackedItems, res, req)
	}
	return nil
}

func (s *Server) handlePackerPackItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-pack-item")
		return s.goRoutineWrapper(s.PackerPackItem, res, req)
	}
	return nil
}

func (s *Server) handlePackerCancelOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-pack")
		return s.CancelPackSalesOrder(res, req)
	}
	return nil
}

func (s *Server) handlePackerAllocateSpace(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-allocate-space")
		return s.goRoutineWrapper(s.PackerAllocateSpace, res, req)
	}
	return nil
}

func (s *Server) handleCheckoutLockItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "checkout-lock-items")
		return s.goRoutineWrapper(s.handlePostCheckoutLockItems, res, req)
	}

	return nil
}

func (s *Server) handleCheckoutPayment(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "checkout-payment")
		return s.goRoutineWrapper(s.handlePostCheckoutPayment, res, req)
	}
	return nil
}

func (s *Server) handleCancelCheckout(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cancel-checkout")

		return s.goRoutineWrapper(s.HandleCancelCheckoutCart, res, req)

	}

	return nil
}

func (s *Server) handleDeliveryPartner(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("[POST]", "delivery_partner")
		return s.goRoutineWrapper(s.Handle_Delivery_Partner_Login, res, req)

	} else if req.Method == "PUT" {
		print_path("[PUT]", "delivery_partner")
		return s.goRoutineWrapper(s.Handle_Delivery_Partner_FCM_Token, res, req)

	} else if req.Method == "GET" {
		print_path("[GET]", "delivery_partner")
		return s.goRoutineWrapper(s.Handle_Get_Delivery_Partners, res, req)

	}
	return nil
}

func (s *Server) handleDeliveryPartnerLogin(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery-partner-login")

		return s.goRoutineWrapper(s.HandlePostDeliveryPartnerLogin, res, req)

	}

	return nil
}

func (s *Server) handleDeliveryPartnerCheckOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_check_order")
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		if len(requestBody) == 1 {
			if _, ok := requestBody["phone"]; ok {
				return s.goRoutineWrapper(s.handleCheckAssignedOrder, res, newReq)
			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		}
	}

	return nil
}

func (s *Server) handleDeliveryPartnerMoveOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_move_order")

		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		if len(requestBody) == 3 {
			if _, ok := requestBody["status"]; ok {
				if _, ok := requestBody["order_id"]; ok {
					if _, ok := requestBody["phone"]; ok {
						// If the key is delivery_partner_id
						return s.goRoutineWrapper(s.handleCheckAssignedOrder, res, newReq)
					}
				}
			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		}
	}

	return nil
}

func (s *Server) handleSalesOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "sales_order")

		return s.goRoutineWrapper(s.Handle_Get_Sales_Orders, res, req)

	} else if req.Method == "POST" {
		print_path("POST", "sales_order")

		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		// Check if the body has exactly 2 keys
		if len(requestBody) == 1 {
			if _, ok := requestBody["delivery_partner_id"]; ok {
				// If the key is delivery_partner_id
				print_path("POST", "sales_order delivery_partner_id")
				return s.goRoutineWrapper(s.handleGetOrdersByDeliveryPartnerId, res, newReq)

			} else if _, ok := requestBody["customer_id"]; ok {
				// If the key is customer_id
				print_path("POST", "sales_order customer_id")

				// Adjust the handler function to handle requests with customer_id
				return s.goRoutineWrapper(s.handleGetOrdersByCustomerId, res, newReq)

			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		} else if len(requestBody) == 2 {
			return s.goRoutineWrapper(s.handleOrdersByCartIdCustomerId, res, newReq)
		}
	}
	return nil
}

func (s *Server) handleStoreSalesOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "store_sales_order")

		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		// Check if the body has exactly 2 keys
		if len(requestBody) == 1 {
			if _, ok := requestBody["store_id"]; ok {
				return s.goRoutineWrapper(s.handleReceivedOrderByStore, res, newReq)
			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		} else if len(requestBody) == 2 {
			if _, ok := requestBody["store_id"]; !ok {
				return errors.New("missing store_id in request body")
			}
			if _, ok := requestBody["order_id"]; !ok {
				return errors.New("missing order_id in request body")
			}
			return s.goRoutineWrapper(s.handleOrderItemsByStoreAndOrderId, res, newReq)

		}
		return errors.New("invalid parameter in request body")
	}

	return nil
}

func (s *Server) handleSalesOrderStore(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "store_sales_order")

		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		// Check if the body has exactly 2 keys
		if len(requestBody) == 1 {
			if _, ok := requestBody["store_id"]; ok {
				return s.goRoutineWrapper(s.handleReceivedOrderByStore, res, newReq)
			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		}
		return errors.New("invalid parameter in request body")
	}

	return nil
}

func (s *Server) handleSalesOrderDetails(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "store_sales_order")
		return s.goRoutineWrapper(s.handleSalesOrderDetailsPOST, res, req)
	}

	return nil
}

func (s *Server) handleAddress(res http.ResponseWriter, req *http.Request) error {
	// add address or get address by customer id
	if req.Method == "POST" {
		print_path("POST", "address")

		// Check the content of the request body to determine which handler to invoke
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}
		// Check if only 'customer_id' is present in the request body
		if _, exists := requestBody["customer_id"]; exists {
			if len(requestBody) == 1 {
				return s.goRoutineWrapper(s.Handle_Get_Address_By_Customer_Id, res, newReq)
			} else if len(requestBody) == 2 {
				return s.goRoutineWrapper(s.handleGetDefaultAddress, res, newReq)
			} else if len(requestBody) == 3 {
				return s.goRoutineWrapper(s.handleMakeDefaultAddress, res, newReq)
			} else {
				print("Create Address")
				return s.goRoutineWrapper(s.Handle_Create_Address, res, newReq)

			}
		}
	} else if req.Method == "DELETE" {
		print_path("DELETE", "address")
		return s.goRoutineWrapper(s.handleDeleteAddress, res, req)
	}
	return nil
}

func (s *Server) handleDeliverTo(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "deliver-to")
		return s.goRoutineWrapper(s.handleDeliverToAddress, res, req)

	}

	return nil
}

func (s *Server) handleBrand(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "brand")
		return s.goRoutineWrapper(s.handleCreateBrand, res, req)

	} else if req.Method == "GET" {
		print_path("GET", "brand")
		return s.goRoutineWrapper(s.handleGetBrands, res, req)

	}
	return nil
}

func (s *Server) handlePhonePeVerifyPayment(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "phonepe-check-status")
		return s.goRoutineWrapper(s.handlePhonePeCheckStatus, res, req)
	}

	return nil
}

func (s *Server) handlePhonePeCallback(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "phonepe-callback")
		return s.goRoutineWrapper(s.handlePhonePePaymentCallback, res, req)

	}

	return nil
}

func (s *Server) handlePhonePe(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "phonepe")
		return s.goRoutineWrapper(s.handlePhonePePaymentInit, res, req)

	}

	return nil
}

func (s *Server) handlePaymentVerify(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "payment-verify")
		return s.goRoutineWrapper(s.PaymentVerify, res, req)
	}

	return nil
}

func (s *Server) handleSendOtp(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "send-otp")

		return s.goRoutineWrapper(s.handleSendOtpMSG91, res, req)

	}

	return nil
}

func (s *Server) handleVerifyOtp(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "verify-otp")

		return s.goRoutineWrapper(s.handleVerifyOtpMSG91, res, req)

	}

	return nil
}

func (s *Server) handleShelfCRUD(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "create-shelf")
		return s.goRoutineWrapper(s.HandleCreateShelf, res, req)
	} else if req.Method == "GET" {
		print_path("GET", "get-shelf")
		return s.goRoutineWrapper(s.HandleGetShelf, res, req)
	}

	return nil
}

func (s *Server) handleLockStock(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "create-lock-stock")
		return s.goRoutineWrapper(s.HandleLockStockCloudTask, res, req)
	}

	return nil
}

func print_path(rest_type string, table string) {
	fmt.Printf("\n [%s] - %s \n", rest_type, table)
}
