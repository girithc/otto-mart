package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type HandlerFunc func(http.ResponseWriter, *http.Request) error

type AuthBody struct {
	PhoneAuth string `json:"phone_auth"`
	TokenAuth string `json:"token_auth"`
}

const numAuthFields = 2

func (s *Server) goRoutineWrapperBase(handler HandlerFunc, res http.ResponseWriter, req *http.Request) error {
	resultChan := make(chan error, 1) // Create a channel to capture the result

	go func() {
		err := handler(res, req)
		resultChan <- err // Send the result error to the channel
	}()

	print(handler)
	return <-resultChan
}

func (s *Server) goRoutineWrapper(handlerID string, handler HandlerFunc, res http.ResponseWriter, req *http.Request) error {
	permission, exists := authRequirements[handlerID]
	if !exists {
		return fmt.Errorf("handler authentication requirement not defined")
	}
	if req.Method != "POST" || !permission.AuthRequired {
		resultChan := make(chan error, 1)
		go func() {
			err := handler(res, req)
			resultChan <- err
		}()
		return <-resultChan
	} else {
		resultChan := make(chan error, 1)
		go func() {
			var requestBody AuthBody
			bodyBytes, err := io.ReadAll(req.Body)
			if err != nil {
				resultChan <- fmt.Errorf("error reading request body: %v", err)
			}
			req.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
			if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
				resultChan <- fmt.Errorf("error unmarshalling request body: %v", err)
			}

			// Check if handlerID starts with "packer"
			if strings.HasPrefix(handlerID, "packer") {
				// Call AuthenticateRequestPacker for handlers starting with "packer"
				authenticated, role, err := s.store.AuthenticateRequestPacker(requestBody.PhoneAuth, requestBody.TokenAuth)
				if err != nil {
					resultChan <- err
					return
				}

				if authenticated {
					if role == permission.Role || role == "Manager" {
						handlerErr := handler(res, req)
						resultChan <- handlerErr
					} else {
						resultChan <- fmt.Errorf("unauthorized. permission denied for role")
					}
				} else {
					resultChan <- fmt.Errorf("unauthorized access")
				}
				// Add logic here based on the `authenticated` and `role`
			} else if strings.HasPrefix(handlerID, "delivery-partner") {
				authenticated, role, err := s.store.AuthenticateRequestDeliveryPartner(requestBody.PhoneAuth, requestBody.TokenAuth)
				if err != nil {
					resultChan <- err
					return
				}

				if authenticated {
					if role == permission.Role || role == "Manager" {
						handlerErr := handler(res, req)
						resultChan <- handlerErr
					} else {
						resultChan <- fmt.Errorf("unauthorized. permission denied for role")
					}
				} else {
					resultChan <- fmt.Errorf("unauthorized access")
				}
			} else if strings.HasPrefix(handlerID, "manager") {
				authenticated, err := s.store.AuthenticateRequestManager(requestBody.PhoneAuth, requestBody.TokenAuth)
				if err != nil {
					resultChan <- err
					return
				}

				if authenticated {
					handlerErr := handler(res, req)
					resultChan <- handlerErr

				} else {
					resultChan <- fmt.Errorf("unauthorized access")
				}
			} else {

				authenticated, role, err := s.store.AuthenticateRequest(requestBody.PhoneAuth, requestBody.TokenAuth)
				if err != nil {
					resultChan <- err
				}

				if authenticated {
					if role == permission.Role || role == "Manager" {
						handlerErr := handler(res, req)
						resultChan <- handlerErr
					} else {
						resultChan <- fmt.Errorf("unauthorized. permission denied for role")
					}
				} else {
					resultChan <- fmt.Errorf("unauthorized access")
				}
			}
		}()
		return <-resultChan
	}
}

func (s *Server) handleLoginCustomer(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "customer-login")
		return s.goRoutineWrapper(CustomerLoginVerify, s.HandleCustomerLogin, res, req)
	}
	return nil
}

func (s *Server) handleCustomer(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cusromer")
		return s.goRoutineWrapper(CustomerLoginAuto, s.HandleVerifyCustomerLogin, res, req)

	} else if req.Method == "GET" {
		print_path("GET", "customer")
		return s.goRoutineWrapper(CustomerGetAll, s.HandleGetCustomers, res, req)
	}
	return nil
}

func (s *Server) handleLoginPacker(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-login")
		return s.goRoutineWrapper(PackerLogin, s.HandlePackerLogin, res, req)
	}

	return nil
}

func (s *Server) handleShoppingCart(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "shopping_cart")
		return s.goRoutineWrapper(ShoppingCartGetAllActive, s.Handle_Get_All_Active_Shopping_Carts, res, req)

	} else if req.Method == "POST" {
		print_path("POST", "shopping_cart")
		return s.goRoutineWrapper(ShoppingCartGetByCustomer, s.Handle_Get_Shopping_Cart_By_Customer_Id, res, req)
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

			} else {
				// Create a new reader from the decoded data
				requestBodyBytes, _ := json.Marshal(requestBody)
				requestBodyReader := bytes.NewReader(requestBodyBytes)
				return s.Handle_Get_Item_List_From_Cart_Item_By_Customer_Id(res, req, requestBodyReader)
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
		return s.goRoutineWrapper(CartItemDelete, s.Handle_Delete_Cart_item, res, req)
		// return s.Handle_Delete_Cart_item(res, req)
	}
	return nil
}

func (s *Server) handleStoreManager(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		fmt.Println("[GET] - Store(s)")
		return s.goRoutineWrapper(StoreGetAll, s.Handle_Get_Stores, res, req)
	} else if req.Method == "POST" {
		fmt.Println("[POST] - Store")
		return s.goRoutineWrapper(StoreCreate, s.Handle_Create_Store, res, req)
	} else if req.Method == "PUT" {
		fmt.Println("[PUT] - Store")
		return s.goRoutineWrapper(StoreUpdate, s.Handle_Update_Store, res, req)
	} else if req.Method == "DELETE" {
		fmt.Println("[DELETE] - Store")
		return s.goRoutineWrapper(StoreDelete, s.Handle_Delete_Store, res, req)
	}

	return fmt.Errorf("no matching path")
}

// Higher Level Category

func (s *Server) handleHigherLevelCategory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "higher_level_category")

		return s.goRoutineWrapper(HigherLevelCategoryGetAll, s.Handle_Get_Higher_Level_Categories, res, req)

	} else if req.Method == "POST" {
		return s.goRoutineWrapper(HigherLevelCategoryCreate, s.Handle_Create_Higher_Level_Category, res, req)
	} else if req.Method == "PUT" {
		print_path("PUT", "higher_level_category")
		return s.goRoutineWrapper(HigherLevelCategoryUpdate, s.Handle_Update_Higher_Level_Category, res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "higher_level_category")
		return s.goRoutineWrapper(HigherLevelCategoryDelete, s.Handle_Delete_Higher_Level_Category, res, req)
	}

	return nil
}

// Category
func (s *Server) handleCategory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "category")
		return s.goRoutineWrapper(CategoryGetAll, s.Handle_Get_Categories, res, req)

	} else if req.Method == "POST" {
		print_path("POST", "category")
		return s.goRoutineWrapper(CategoryCreate, s.Handle_Create_Category, res, req)

	} else if req.Method == "PUT" {
		print_path("PUT", "category")
		return s.goRoutineWrapper(CategoryUpdate, s.Handle_Update_Category, res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "category")
		return s.goRoutineWrapper(CategoryDelete, s.Handle_Delete_Category, res, req)
	}

	fmt.Println("Returning Nil")
	return nil
}

func (s *Server) handleGetCategory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("[GET]", "get-category")
		return s.goRoutineWrapper(CategoryList, s.HandleGetCategoryList, res, req)
	}
	return nil
}

func (s *Server) handleGetBrand(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("[GET]", "get-brand")
		return s.goRoutineWrapper(BrandGetAll, s.HandleGetBrandList, res, req)
	}
	return nil
}

// Category Higher Level Mapping
func (s *Server) handleCategoryHigherLevelMapping(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {

		print_path("GET", "category_higher_level_mapping")
		return s.goRoutineWrapper(CategoryHigherLevelMappingGetAll, s.Handle_Get_Category_Higher_Level_Mappings, res, req)

	} else if req.Method == "POST" {

		print_path("POST", "category_higher_level_mapping")
		return s.goRoutineWrapper(CategoryHigherLevelMappingCreate, s.Handle_Create_Category_Higher_Level_Mapping, res, req)

	} else if req.Method == "PUT" {

		print_path("PUT", "category_higher_level_mapping")
		return s.goRoutineWrapper(CategoryHigherLevelMappingUpdate, s.Handle_Update_Category_Higher_Level_Mapping, res, req)

	} else if req.Method == "DELETE" {

		print_path("DELETE", "category_higher_level_mapping")
		return s.goRoutineWrapper(CategoryHigherLevelMappingDelete, s.Handle_Delete_Category_Higher_Level_Mapping, res, req)

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
			if len(requestBody) == (1 + numAuthFields) {
				return s.goRoutineWrapper(LockedQuantityRemove, s.handleRemoveLockedQuantities, res, newReq)
			} else if len(requestBody) == (2 + numAuthFields) {
				return s.goRoutineWrapper(LockedQuantityUnlock, s.handleUnlockLockQuantities, res, newReq)
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

		if _, barcodeOk := requestBody["barcode"].(string); barcodeOk {
			return s.goRoutineWrapper(ItemUpdateBarcode, s.HandleUpdateItemBarcode, res, newReq)
		} else if _, addStockOk := requestBody["add_stock"].(float64); addStockOk {
			return s.goRoutineWrapper(ItemUpdateAddStock, s.HandleUpdateItemAddStock, res, newReq)
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

		if _, addStockOk := requestBody["add_stock"].(float64); addStockOk {
			if _, itemIdOk := requestBody["item_id"].(float64); itemIdOk {
				if _, storeIdOk := requestBody["store_id"].(float64); storeIdOk {
					return s.goRoutineWrapper(ItemUpdateAddStockByStore, s.HandleItemAddStockByStore, res, newReq)
				}
			}
		}

		if _, barcodeOk := requestBody["barcode"].(string); barcodeOk {
			if _, storeIdOk := requestBody["store_id"].(float64); storeIdOk {
				return s.goRoutineWrapper(ItemByStoreAndBarcode, s.HandleGetItemAddByStore, res, newReq)
			}
		}

	}
	return nil
}

func (s *Server) handleItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "item")
		return s.goRoutineWrapper(ItemGetAll, s.Handle_Get_Items, res, req)

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

		if len(requestBody) == (1 + numAuthFields) {
			return s.goRoutineWrapper(ItemAddStockAll, s.HandleAddStockToItem, res, newReq)
		} else { // is default
			return s.goRoutineWrapper(ItemCreate, s.Handle_Create_Item, res, newReq)
		}

	} else if req.Method == "PUT" {
		print_path("PUT", "item")
		return s.goRoutineWrapper(ItemUpdate, s.Handle_Update_Item, res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "item")
		return s.goRoutineWrapper(ItemDelete, s.Handle_Delete_Item, res, req)
	}
	return nil
}

func (s *Server) handleSearchItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "search item")

		return s.goRoutineWrapper(SearchItems, s.Handle_Post_Search_Items, res, req)

	}
	return nil
}

func (s *Server) handleItemAddQuick(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item-add-quick")
		return s.goRoutineWrapper(ItemAddQuick, s.HandleItemAddQuick, res, req)
	}
	return nil
}

func (s *Server) handleItemEdit(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item-edit")
		return s.goRoutineWrapper(ManagerItemEdit, s.handleItemEditBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerGetItemFinancial(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item-finance")
		return s.goRoutineWrapper(ManagerItemFinanceGet, s.handleManagerGetItemFinanceBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerEditItemFinancial(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "item-finance-edit")
		return s.goRoutineWrapper(ManagerItemFinanceEdit, s.handleManagerEditItemFinanceBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerSearchItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-search-item")
		return s.goRoutineWrapper(ManagerSearchItem, s.handleManagerSearchItemBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerGetTax(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "manager-get-tax")
		return s.goRoutineWrapper(ManagerGetTax, s.handleManagerGetTaxBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerItemStoreCombo(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-item-store-combo")
		return s.goRoutineWrapper(ManagerItemStoreCombo, s.handleManagerItemStoreComboBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerAddNewItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-add-new-item")
		return s.goRoutineWrapper(ManagerAddNewItem, s.handleManagerAddNewItemBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerUpdateItemBarcode(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-update-item-barcode")
		return s.goRoutineWrapper(ManagerUpdateItemBarcode, s.handleManagerUpdateItemBarcodeBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerInitShelf(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-init-shelf")
		return s.goRoutineWrapper(ManagerInitShelf, s.handleManagerInitShelfBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerAssignItemShelf(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-assign-item-shelf")
		return s.goRoutineWrapper(ManagerAssignItemShelf, s.handleManagerAssignItemShelfBasic, res, req)
	}
	return nil
}

func (s *Server) handlePackerFindItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-find-item")
		return s.goRoutineWrapper(PackerFindItem, s.handlePackerFindItemBasic, res, req)
	}
	return nil
}

func (s *Server) handlePackerCompleteOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-complete-order")
		return s.goRoutineWrapper(PackerCompleteOrder, s.handlePackerCompleteOrderBasic, res, req)
	}
	return nil
}

func (s *Server) handlePackerGetCustomerOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-get-order")
		return s.goRoutineWrapper(PackerGetOrder, s.handlePackerGetOrder, res, req)
	}
	return nil
}

func (s *Server) handleManagerFindItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-find-item")
		return s.goRoutineWrapper(ManagerFindItem, s.handlePackerFindItemBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerFCM(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-fcm")
		return s.goRoutineWrapper(ManagerFCM, s.handleManagerFCMBasic, res, req)
	}
	return nil
}

func (s *Server) handleManagerCreateOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-create-order")
		return s.goRoutineWrapper(ManagerCreateOrder, s.handleManagerCreateOrderBasic, res, req)
	}
	return nil
}

func (s *Server) handlePackerLoadItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-load-item")
		return s.goRoutineWrapper(PackerLoadItem, s.handlePackerLoadItemBasic, res, req)
	}
	return nil
}

func (s *Server) handlePackerPackOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-pack")
		return s.goRoutineWrapper(PackerPackOrder, s.GetRecentSalesOrderByStore, res, req)
	}
	return nil
}

func (s *Server) handlePackerFetchItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-fetch-item")
		return s.goRoutineWrapper(PackerFetchItem, s.PackerFetchItem, res, req)
	}
	return nil
}

func (s *Server) handlePackerGetAllItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-get-all-items")
		return s.goRoutineWrapper(PackerGetPackedItems, s.PackerGetAllPackedItems, res, req)
	}
	return nil
}

func (s *Server) handlePackerPackItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-pack-item")
		return s.goRoutineWrapper(PackerPackItem, s.PackerPackItem, res, req)
	}
	return nil
}

func (s *Server) handlePackerCancelOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-pack")
		return s.goRoutineWrapper(PackerCancelOrder, s.CancelPackSalesOrder, res, req)
	}
	return nil
}

func (s *Server) handlePackerCheckOrderToPack(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-check-order-to-pack")
		return s.goRoutineWrapper(PackerCheckOrderToPack, s.PackerCheckOrderToPack, res, req)
	}
	return nil
}

func (s *Server) handlePackerAllocateSpace(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-allocate-space")
		return s.goRoutineWrapper(PackerAllocateSpace, s.PackerAllocateSpace, res, req)
	}
	return nil
}

func (s *Server) handlePackerGetOrderItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer-get-order-items")
		return s.goRoutineWrapper(PackerGetOrderItems, s.PackerGetOrderItems, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerGetOrderItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_get_order_items")
		return s.goRoutineWrapper(DeliveryPartnerGetOrderItems, s.DeliveryPartnerGetOrderItems, res, req)
	}
	return nil
}

func (s *Server) handleCheckoutLockItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "checkout-lock-items")
		return s.goRoutineWrapper(CheckoutLockItems, s.handlePostCheckoutLockItems, res, req)
	}
	return nil
}

func (s *Server) handleCheckoutPayment(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "checkout-payment")
		return s.goRoutineWrapper(CheckoutPayment, s.handlePostCheckoutPayment, res, req)
	}
	return nil
}

func (s *Server) handleCancelCheckout(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cancel-checkout")
		return s.goRoutineWrapper(CheckoutCancel, s.HandleCancelCheckoutCart, res, req)
	}
	return nil
}

func (s *Server) handleCustomerPlacedOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "customer-placed-order")
		return s.goRoutineWrapper(CustomerPlacedOrder, s.handleGetCustomerPlacedOrder, res, req)
	}
	return nil
}

func (s *Server) handleCustomerPickupOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "customer-pickup-order")
		return s.goRoutineWrapper(CustomerPickupOrder, s.handleCustomerPickup, res, req)
	}
	return nil
}

func (s *Server) handleCustomerCartDetails(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "customer-cart-details")
		return s.goRoutineWrapper(CustomerCartDetails, s.handleGetCustomerCartDetails, res, req)
	}
	return nil
}

func (s *Server) handleGetCartSlots(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cart-slot")
		return s.goRoutineWrapper(CartSlots, s.handleGetCustomerCartSlots, res, req)
	}
	return nil
}

func (s *Server) handleAssignCartSlots(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "cart-slot")
		return s.goRoutineWrapper(AssignCartSlots, s.handleAssignCustomerCartSlots, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartner(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "PUT" {
		print_path("[PUT]", "delivery_partner")
		return s.goRoutineWrapper(DeliveryPartnerUpdate, s.Handle_Delivery_Partner_FCM_Token, res, req)

	} else if req.Method == "GET" {
		print_path("[GET]", "delivery_partner")
		return s.goRoutineWrapper(DeliveryPartnerGet, s.Handle_Get_Delivery_Partners, res, req)

	}
	return nil
}

func (s *Server) handleDeliveryPartnerLogin(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery-partner-login")

		return s.goRoutineWrapper(DeliveryPartnerLogin, s.HandlePostDeliveryPartnerLogin, res, req)

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

		if _, ok := requestBody["phone"]; ok {
			return s.goRoutineWrapper(DeliveryPartnerCheckAssignedOrder, s.handleCheckAssignedOrder, res, newReq)
		} else {
			// Handle the case where the key is neither delivery_partner_id nor customer_id
			return errors.New("invalid parameter in request body")
		}

	}
	return nil
}

func (s *Server) handleDeliveryPartnerAcceptOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_accept_order")
		return s.goRoutineWrapper(DeliveryPartnerAcceptOrder, s.DeliveryPartnerAcceptOrder, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerGetAssignedOrders(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_get_assigned_orders")
		return s.goRoutineWrapper(DeliveryPartnerGetAssignedOrder, s.DeliveryPartnerGetAssignedOrder, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerPickupOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_pickup_order")
		return s.goRoutineWrapper(DeliveryPartnerPickupOrder, s.DeliveryPartnerPickupOrder, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerGoDeliverOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_go_delivery_order")
		return s.goRoutineWrapper(DeliveryPartnerGoDeliverOrder, s.DeliveryPartnerGoDeliverOrder, res, req)
	}
	return nil
}

func (s *Server) handleArriveDestination(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_go_delivery_order")
		return s.goRoutineWrapper(DeliveryPartnerArriveDestination, s.DeliveryPartnerArriveDestination, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerDispatchOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_dispatch_order")
		return s.goRoutineWrapper(DeliveryPartnerDispatchOrder, s.DeliveryPartnerDispatchOrder, res, req)
	}
	return nil
}
func (s *Server) handleCustomerDispatchOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "customer_dispatch_order")
		return s.goRoutineWrapper(CustomerDispatchOrder, s.DeliveryPartnerDispatchOrder, res, req)
	}
	return nil
}

func (s *Server) handlePackerDispatchOrderHistory(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "packer_dispatch_order_history")
		return s.goRoutineWrapper(PackerDispatchOrderHistory, s.PackerDispatchOrderHistory, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerArrive(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_arrive")
		return s.goRoutineWrapper(DeliveryPartnerArrive, s.DeliveryPartnerArrive, res, req)
	}
	return nil
}

func (s *Server) handleDeliveryPartnerCompleteOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_complete_order")
		return s.goRoutineWrapper(DeliveryPartnerCompleteOrder, s.DeliveryPartnerCompleteOrder, res, req)
	}

	return nil
}

func (s *Server) handleDeliveryPartnerGetOrderDetails(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "delivery_partner_get_order_details")
		return s.goRoutineWrapper(DeliveryPartnerGetOrderDetails, s.DeliveryPartnerGetOrderDetails, res, req)
	}
	return nil
}

func (s *Server) handleSalesOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "sales_order")

		return s.goRoutineWrapper(SalesOrderGetAll, s.Handle_Get_Sales_Orders, res, req)

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
		if len(requestBody) == (1 + numAuthFields) {
			if _, ok := requestBody["delivery_partner_id"]; ok {
				// If the key is delivery_partner_id
				print_path("POST", "sales_order delivery_partner_id")
				return s.goRoutineWrapper(SalesOrderGetByDeliveryPartner, s.handleGetOrdersByDeliveryPartnerId, res, newReq)

			} else if _, ok := requestBody["customer_id"]; ok {
				// If the key is customer_id
				print_path("POST", "sales_order customer_id")

				// Adjust the handler function to handle requests with customer_id
				return s.goRoutineWrapper(SalesOrderGetByCustomer, s.handleGetOrdersByCustomerId, res, newReq)

			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		} else if len(requestBody) == (2 + numAuthFields) {
			return s.goRoutineWrapper(SalesOrderGetByCartIdCustomerId, s.handleOrdersByCartIdCustomerId, res, newReq)
		}
	}
	return nil
}

func (s *Server) handlePackerGetOrderByOTP(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "sales_order_items")
		return s.goRoutineWrapper(PackerGetOrderByOTP, s.handlePackerGetOrder, res, req)
	}
	return nil
}
func (s *Server) handleCheckForPlacedOrder(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "check-for-placed-order")
		return s.goRoutineWrapper(CheckForPlacedOrder, s.CheckForPlacedOrder, res, req)
	}
	return nil
}

func (s *Server) handleStoreAddress(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "store_address")
		return s.goRoutineWrapper(StoreAddressGet, s.HandleGetStoreAddress, res, req)
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

		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
		}

		// Assuming that the request body is in JSON format, let's unmarshal it into a map
		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}

		if len(requestBody) == (1 + numAuthFields) {
			if _, ok := requestBody["store_id"]; ok {
				return s.goRoutineWrapper(StoreReceivedSalesOrder, s.handleReceivedOrderByStore, res, newReq)
			} else {
				// Handle the case where the key is neither delivery_partner_id nor customer_id
				return errors.New("invalid parameter in request body")
			}
		} else if len(requestBody) == (2 + numAuthFields) {
			if _, ok := requestBody["store_id"]; !ok {
				return errors.New("missing store_id in request body")
			}
			if _, ok := requestBody["order_id"]; !ok {
				return errors.New("missing order_id in request body")
			}
			return s.goRoutineWrapper(StoreGetSalesOrderItemsBySalesOrderId, s.handleOrderItemsByStoreAndOrderId, res, newReq)
		}
		return errors.New("invalid parameter in request body")
	}
	return nil
}

func (s *Server) handleSalesOrderDetails(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "store_sales_order")
		return s.goRoutineWrapper(SalesOrderDetailsByCustomerAndOrderId, s.handleSalesOrderDetailsPOST, res, req)
	}

	return nil
}

func (s *Server) handleAddress(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "address")

		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
		}

		var requestBody map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &requestBody); err != nil {
			return err
		}
		if _, exists := requestBody["customer_id"]; exists {
			if len(requestBody) == (1 + numAuthFields) {
				return s.goRoutineWrapper(AddressGetByCustomerId, s.Handle_Get_Address_By_Customer_Id, res, newReq)
			} else if len(requestBody) == (2 + numAuthFields) {
				return s.goRoutineWrapper(AddressGetDefaultByCustomerId, s.handleGetDefaultAddress, res, newReq)
			} else if len(requestBody) == (3 + numAuthFields) {
				return s.goRoutineWrapper(AddressMakeDefault, s.handleMakeDefaultAddress, res, newReq)
			} else {
				print("Create Address")
				return s.goRoutineWrapper(AddressCreate, s.Handle_Create_Address, res, newReq)
			}
		}
	} else if req.Method == "DELETE" {
		print_path("DELETE", "address")
		return s.goRoutineWrapper(AddressDelete, s.handleDeleteAddress, res, req)
	}
	return nil
}

func (s *Server) handleDeliverTo(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "deliver-to")
		return s.goRoutineWrapper(AddressDeliverTo, s.handleDeliverToAddress, res, req)
	}
	return nil
}

func (s *Server) handleVendorList(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "vendor-list")
		return s.goRoutineWrapper(VendorGetAll, s.handleGetVendorList, res, req)
	}
	return nil
}

func (s *Server) handleAddVendor(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "vendor")
		return s.goRoutineWrapper(VendorAdd, s.handleCreateVendor, res, req)
	}
	return nil
}

func (s *Server) handleEditVendor(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "edit-vendor")
		return s.goRoutineWrapper(VendorEdit, s.handleEditVendorDetails, res, req)
	}
	return nil
}

func (s *Server) handleBrand(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "brand")
		return s.goRoutineWrapper(BrandCreate, s.handleCreateBrand, res, req)
	} else if req.Method == "GET" {
		print_path("GET", "brand")
		return s.goRoutineWrapper(BrandGet, s.handleGetBrands, res, req)
	}
	return nil
}

func (s *Server) handlePhonePeVerifyPayment(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "phonepe-check-status")
		return s.goRoutineWrapper(PhonePeCheckStatus, s.handlePhonePeCheckStatus, res, req)
	}
	return nil
}

func (s *Server) handlePhonePeCallback(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "phonepe-callback")
		return s.goRoutineWrapper(PhonePeCallback, s.handlePhonePePaymentCallback, res, req)
	}
	return nil
}

func (s *Server) handlePhonePe(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "phonepe")
		return s.goRoutineWrapper(PhonePePaymentInit, s.handlePhonePePaymentInit, res, req)
	}
	return nil
}

func (s *Server) handlePaymentVerify(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "payment-verify")
		return s.goRoutineWrapper(PhonePePaymentVerify, s.PaymentVerify, res, req)
	}
	return nil
}

func (s *Server) handleSendOtp(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "send-otp")
		return s.goRoutineWrapper(OtpSend, s.handleSendOtpMSG91, res, req)
	}
	return nil
}

func (s *Server) handleVerifyOtp(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "verify-otp")
		return s.goRoutineWrapper(OtpVerify, s.handleVerifyOtpMSG91, res, req)
	}
	return nil
}

func (s *Server) handleSendOtpPacker(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "send-otp-packer")
		return s.goRoutineWrapper(OtpSendPacker, s.handleSendOtpPackerMSG91, res, req)
	}
	return nil
}

func (s *Server) handleVerifyOtpPacker(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "verify-otp-packer")
		return s.goRoutineWrapper(OtpVerifyPacker, s.handleVerifyOtpPackerMSG91, res, req)
	}
	return nil
}

func (s *Server) handleSendOtpDeliveryPartner(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "send-otp-delivery-partner")
		return s.goRoutineWrapper(OtpSendDeliveryPartner, s.handleSendOtpDeliveryPartnerMSG91, res, req)
	}
	return nil
}

func (s *Server) handleVerifyOtpDeliveryPartner(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "verify-otp-delivery-partner")
		return s.goRoutineWrapper(OtpVerifyDeliveryPartner, s.handleVerifyOtpDeliveryPartnerMSG91, res, req)
	}
	return nil
}

func (s *Server) handleSendOtpManager(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "send-otp-manager")
		return s.goRoutineWrapper(OtpSendManager, s.handleSendOtpManagerMSG91, res, req)
	}
	return nil
}

func (s *Server) handleVerifyOtpManager(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "verify-otp-manager")
		return s.goRoutineWrapper(OtpVerifyManager, s.handleVerifyOtpManagerMSG91, res, req)
	}
	return nil
}

func (s *Server) handleManagerLogin(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-login")
		return s.goRoutineWrapper(ManagerLogin, s.HandleManagerLogin, res, req)
	}
	return nil
}

func (s *Server) handleManagerItems(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "manager-items")
		return s.goRoutineWrapper(ManagerItems, s.HandleManagerItems, res, req)
	}
	return nil
}

func (s *Server) handleManagerGetItem(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "manager-get-items")
		return s.goRoutineWrapper(ManagerGetItems, s.HandleManagerGetItem, res, req)
	}
	return nil
}

func (s *Server) handleShelfCRUD(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "create-shelf")
		return s.goRoutineWrapper(ShelfCreate, s.HandleCreateShelf, res, req)
	} else if req.Method == "GET" {
		print_path("GET", "get-shelf")
		return s.goRoutineWrapper(ShelfGetAll, s.HandleGetShelf, res, req)
	}
	return nil
}

func (s *Server) handleLockStock(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "create-lock-stock")
		return s.goRoutineWrapper(LockStockCloudTask, s.HandleLockStockCloudTask, res, req)
	}
	return nil
}

func (s *Server) handleNeedToUpdate(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "need-to-update")
		return s.goRoutineWrapper(NeedToUpdate, s.HandleNeedToUpdate, res, req)
	}
	return nil
}

func (s *Server) handleGenInvoice(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "genInvoice")
		return s.goRoutineWrapper(GenInvoice, s.HandleGenOrderInvoices, res, req)
	}
	return nil
}

func (s *Server) handleExport(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "export data")
		return s.goRoutineWrapper(GenInvoice, s.HandleExportAllData, res, req)
	}
	return nil
}

func print_path(rest_type string, table string) {
	fmt.Printf("\n [%s] - %s \n", rest_type, table)
}
