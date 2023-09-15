package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
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
            } else {
                // Create a new reader from the decoded data
                requestBodyBytes, _ := json.Marshal(requestBody)
                requestBodyReader := bytes.NewReader(requestBodyBytes)
                
                // Pass the new reader to Handle_Add_Cart_Item
                return s.Handle_Get_All_Cart_Items(res, req, requestBodyReader)
            }
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

        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Get_Higher_Level_Categories(res, req)
        }

        // Start the task in a worker and pass a callback to capture the result
        workerPool.StartWorker(task, func(err error) {
            resultChan <- err // Send the result to the channel
        })

        // Wait for the result and return it
        return <-resultChan

	} else if req.Method == "POST" {

		//print_path("POST", "higher_level_category")
        resultChan := make(chan error, 1) // Create a channel to capture the result

        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Create_Higher_Level_Category(res, req)
        }

        // Start the task in a worker and pass a callback to capture the result
        workerPool.StartWorker(task, func(err error) {
            resultChan <- err // Send the result to the channel
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

        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Get_Categories(res, req)
        }

        // Start the task in a worker and pass a callback to capture the result
        workerPool.StartWorker(task, func(err error) {
            resultChan <- err // Send the result to the channel
        })

        // Wait for the result and return it
        return <-resultChan

	} else if req.Method == "POST" {
        print_path("POST", "category")
        resultChan := make(chan error, 1) // Create a channel to capture the result

        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Create_Category(res, req)
        }

        // Start the task in a worker and pass a callback to capture the result
        workerPool.StartWorker(task, func(err error) {
            resultChan <- err // Send the result to the channel
        })

        // Wait for the result and return it
        return <-resultChan

	}  else if req.Method == "PUT" {

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
        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Get_Items(res, req)
        }

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(err error) {
			resultChan <- err // Send the result to the channel
		})

        // Collect all results
        
		return  <-resultChan
       
    } else if req.Method == "POST" {
        print_path("POST", "item")
        resultChan := make(chan error, 1) // Create a channel to capture the result

        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Create_Item(res, req)
        }

        // Start the task in a worker and pass a callback to capture the result
        workerPool.StartWorker(task, func(err error) {
            resultChan <- err // Send the result to the channel
        })

        // Wait for the result and return it
        return <-resultChan

	}  else if req.Method == "PUT" {

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
        task := func() error {
            // Your actual GET category logic here
            return s.Handle_Post_Search_Items(res, req)
        }

		// Start the task in a worker and pass a callback to capture the result
		workerPool.StartWorker(task, func(err error) {
			resultChan <- err // Send the result to the channel
		})

        // Collect all results
        
		return  <-resultChan
       
    }

	return nil
}

func print_path(rest_type string, table string) {
	fmt.Printf("\n [%s] - %s \n", rest_type, table)
}

