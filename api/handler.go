package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/girithc/pronto-go/worker"
)

// Store

func (s *Server) handleCustomer(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		fmt.Println("Login Initiated")
		return s.Handle_Customer_Login(res, req)
	} else if req.Method == "GET" {
		print_path("[GET]", "customer")
		return s.Handle_Get_Customers(res, req)
	}
	return nil
}

func (s *Server) handleShoppingCart(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {
		print_path("GET", "shopping_cart")
		return s.Handle_Get_All_Active_Shopping_Carts(res, req)
	} else if req.Method == "POST" {
		print_path("POST", "shopping_cart")
		return s.Handle_Get_Shopping_Cart_By_Customer_Id(res, req)
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

		// Check if the desired field exists in the request body
		if cartId, cartOk := requestBody["cart_id"].(float64); cartOk {
			// Field exists, you can take further action
			cartID := int(cartId) // Convert to int if it's a valid integer
			fmt.Printf("Field 'cart_id' found with value (numeric): %d\n", cartID)
			// Redirect or perform other actions based on the field's value
			if itemId, itemOk := requestBody["item_id"].(float64); itemOk {
				// Field exists, you can take further action
				itemID := int(itemId) // Convert to int if it's a valid integer
				fmt.Printf("Field 'item_id' found with value (numeric): %d\n", itemID)
				// Redirect or perform other actions based on the field's value

				// Create a new reader from the decoded data
				requestBodyBytes, _ := json.Marshal(requestBody)
				requestBodyReader := bytes.NewReader(requestBodyBytes)

				// Pass the new reader to Handle_Add_Cart_Item
				return s.Handle_Add_Cart_Item(res, req, requestBodyReader)
			} else if itemList, itemListOk := requestBody["items"].(bool); itemListOk {
				// Create a new reader from the decoded data
				requestBodyBytes, _ := json.Marshal(requestBody)
				requestBodyReader := bytes.NewReader(requestBodyBytes)

				if itemList {
					return s.Handle_Get_Item_List_From_Cart_Item(res, req, requestBodyReader)
				} else {
					return s.Handle_Get_All_Cart_Items(res, req, requestBodyReader)
				}

			}
		} else if customerId_float, customerOk := requestBody["customer_id"].(float64); customerOk {
			customerId_int := int(customerId_float) // Convert to int if it's a valid integer
			fmt.Printf("Field 'cart_id' found with value (numeric): %d\n", customerId_int)

			// Create a new reader from the decoded data
			requestBodyBytes, _ := json.Marshal(requestBody)
			requestBodyReader := bytes.NewReader(requestBodyBytes)

			// Pass the new reader to Handle_Add_Cart_Item
			return s.Handle_Get_Item_List_From_Cart_Item_By_Customer_Id(res, req, requestBodyReader)
		}

	} else if req.Method == "DELETE" {
		print_path("DELETE", "cart-item")
		return s.Handle_Delete_Cart_item(res, req)
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
		return s.Handle_Get_Stores(res, req)
	} else if req.Method == "POST" {
		fmt.Println("[POST] - Store")
		return s.Handle_Create_Store(res, req)
	} else if req.Method == "PUT" {
		fmt.Println("[PUT] - Store")
		return s.Handle_Update_Store(res, req)
	} else if req.Method == "DELETE" {
		fmt.Println("[DELETE] - Store")
		return s.Handle_Delete_Store(res, req)
	}

	return fmt.Errorf("no matching path")
}

// Higher Level Category

func (s *Server) handleHigherLevelCategory(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "GET" {
		print_path("GET", "higher_level_category")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Get_Higher_Level_Categories(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	} else if req.Method == "POST" {
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Create_Higher_Level_Category(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	} else if req.Method == "PUT" {
		print_path("PUT", "higher_level_category")
		return s.Handle_Update_Higher_Level_Category(res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "higher_level_category")
		return s.Handle_Delete_Higher_Level_Category(res, req)
	}

	return nil
}

// Category
func (s *Server) handleCategory(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool // Access the WorkerPool from the Server instance

	if req.Method == "GET" {
		print_path("GET", "category")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Get_Categories(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	} else if req.Method == "POST" {
		print_path("POST", "category")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Create_Category(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	} else if req.Method == "PUT" {
		print_path("PUT", "category")
		return s.Handle_Update_Category(res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "category")
		return s.Handle_Delete_Category(res, req)
	}

	fmt.Println("Returning Nil")
	return nil
}

// Category Higher Level Mapping

func (s *Server) handleCategoryHigherLevelMapping(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "GET" {

		print_path("GET", "category_higher_level_mapping")
		return s.Handle_Get_Category_Higher_Level_Mappings(res, req)

	} else if req.Method == "POST" {

		print_path("POST", "category_higher_level_mapping")
		return s.Handle_Create_Category_Higher_Level_Mapping(res, req)

	} else if req.Method == "PUT" {

		print_path("PUT", "category_higher_level_mapping")
		return s.Handle_Update_Category_Higher_Level_Mapping(res, req)

	} else if req.Method == "DELETE" {

		print_path("DELETE", "category_higher_level_mapping")
		return s.Handle_Delete_Category_Higher_Level_Mapping(res, req)

	}

	return nil
}

// Item
func (s *Server) handleItem(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "GET" {
		print_path("GET", "item")

		// Create a channel to capture the results of multiple runs
		resultChan := make(chan error, 1)

		// Define the task function to run
		task := func() worker.Result {
			err := s.Handle_Get_Items(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Collect all results and return the first one (since you're using a buffer of size 1)
		return <-resultChan

	} else if req.Method == "POST" {
		print_path("POST", "item")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Create_Item(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	} else if req.Method == "PUT" {
		print_path("PUT", "item")
		return s.Handle_Update_Item(res, req)

	} else if req.Method == "DELETE" {
		print_path("DELETE", "item")
		return s.Handle_Delete_Item(res, req)
	}

	return nil
}

func (s *Server) handleSearchItem(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "POST" {
		print_path("POST", "search item")

		// Create a channel to capture the results of multiple runs
		resultChan := make(chan error, 1)

		// Define the task function to run
		task := func() worker.Result {
			err := s.Handle_Post_Search_Items(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Collect all results and return the first one (since you're using a buffer of size 1)
		return <-resultChan
	}

	return nil
}

func (s *Server) handleCheckout(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("POST", "checkout")

		// Read and store the request body
		bodyBytes, err := io.ReadAll(req.Body)
		if err != nil {
			return err // or handle this error accordingly
		}

		// You can then create a new request body from bodyBytes to pass to your handler
		newReq := &http.Request{
			Body: io.NopCloser(bytes.NewBuffer(bodyBytes)),
			// ... copy other needed fields from the original request
		}

		// Spawn a goroutine to handle the checkout process
		go func() {
			err := s.Handle_Checkout_Cart(res, newReq)
			if err != nil {
				// Handle the error, e.g., log it
				fmt.Printf("Error handling checkout: %s\n", err)
			}
		}()

		// Return an acknowledgment to the user immediately or some placeholder response
		// Example:
		res.WriteHeader(http.StatusOK)
		res.Write([]byte("Checkout initiated, please wait..."))

		return nil
	}
	return nil
}

func (s *Server) handleCancelCheckout(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "POST" {
		print_path("POST", "cancel-checkout")

		// Create a channel to capture the results of multiple runs
		resultChan := make(chan error, 1)

		// Define the task function to run
		task := func() worker.Result {
			err := s.Handle_Cancel_Checkout_Cart(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Collect all results and return the first one (since you're using a buffer of size 1)
		return <-resultChan
	}

	return nil
}

func (s *Server) handleDeliveryPartner(res http.ResponseWriter, req *http.Request) error {
	if req.Method == "POST" {
		print_path("[POST]", "delivery_partner")
		return s.Handle_Delivery_Partner_Login(res, req)
	} else if req.Method == "PUT" {
		print_path("[PUT]", "delivery_partner")
		return s.Handle_Delivery_Partner_FCM_Token(res, req)
	} else if req.Method == "GET" {
		print_path("[GET]", "delivery_partner")
		return s.Handle_Get_Delivery_Partners(res, req)
	}
	return nil
}

func (s *Server) handleSalesOrder(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "GET" {
		print_path("GET", "sales_order")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Get_Sales_Orders(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	}

	return nil
}

func (s *Server) handleAddress(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "POST" {
		print_path("POST", "address")
		resultChan := make(chan error, 1) // Create a channel to capture the result

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

		// Define the task based on the request content
		var task func() worker.Result

		// Check if only 'customer_id' is present in the request body
		if _, exists := requestBody["customer_id"]; exists && len(requestBody) == 1 {
			task = func() worker.Result {
				err := s.Handle_Get_Address_By_Customer_Id(res, newReq)
				return worker.Result{Error: err}
			}
		} else {
			task = func() worker.Result {
				err := s.Handle_Create_Address(res, newReq)
				return worker.Result{Error: err}
			}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan
	}
	return nil
}

func (s *Server) handleBrand(res http.ResponseWriter, req *http.Request) error {
	workerPool := s.workerPool

	if req.Method == "POST" {
		print_path("POST", "brand")
		resultChan := make(chan error, 1) // Create a channel to capture the result

		task := func() worker.Result {
			err := s.Handle_Create_Brand(res, req)
			return worker.Result{Error: err}
		}

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(result worker.Result) {
			resultChan <- result.Error // Send the result error to the channel
		})

		// Wait for the result and return it
		return <-resultChan

	}
	return nil
}

func print_path(rest_type string, table string) {
	fmt.Printf("\n [%s] - %s \n", rest_type, table)
}
