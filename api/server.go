package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/store"
	"github.com/girithc/pronto-go/worker"
)

type Server struct {
	listen_address string
	store          *store.PostgresStore
	workerPool     *worker.WorkerPool
}

func NewServer(listen_address string, store *store.PostgresStore, workerPool *worker.WorkerPool) *Server {
	return &Server{
		listen_address: listen_address,
		store:          store,
		workerPool:     workerPool,
	}
}

func (s *Server) Run( /*gs *GoogleServer*/ ) {
	// http.HandleFunc("/gcloud/sign", gs.handleGoogleSignManager)

	http.HandleFunc("/store/available", makeHTTPHandleFunc(s.handleStoreClient))
	http.HandleFunc("/store", makeHTTPHandleFunc(s.handleStoreManager))

	http.HandleFunc("/higher-level-category", makeHTTPHandleFunc(s.handleHigherLevelCategory))

	http.HandleFunc("/category-higher-level-mapping", makeHTTPHandleFunc(s.handleCategoryHigherLevelMapping))

	http.HandleFunc("/category", makeHTTPHandleFunc(s.handleCategory))
	http.HandleFunc("/item-store", makeHTTPHandleFunc(s.handleItemStore))
	http.HandleFunc("/item", makeHTTPHandleFunc(s.handleItem))
	http.HandleFunc("/search-item", makeHTTPHandleFunc(s.handleSearchItem))

	http.HandleFunc("/customer", makeHTTPHandleFunc(s.handleCustomer))
	http.HandleFunc("/shopping-cart", makeHTTPHandleFunc(s.handleShoppingCart))
	http.HandleFunc("/cart-item", makeHTTPHandleFunc(s.handleCartItem))

	http.HandleFunc("/checkout-lock-items", makeHTTPHandleFunc(s.handleCheckoutLockItems))
	http.HandleFunc("/checkout-payment", makeHTTPHandleFunc(s.handleCheckoutPayment))
	http.HandleFunc("/checkout-cancel", makeHTTPHandleFunc(s.handleCancelCheckout))
	http.HandleFunc("/checkout", makeHTTPHandleFunc(s.handleCheckout))

	http.HandleFunc("/delivery-partner", makeHTTPHandleFunc(s.handleDeliveryPartner))
	http.HandleFunc("/sales-order", makeHTTPHandleFunc(s.handleSalesOrder))

	http.HandleFunc("/address", makeHTTPHandleFunc(s.handleAddress))
	http.HandleFunc("/brand", makeHTTPHandleFunc(s.handleBrand))

	fmt.Println("Listening PORT", s.listen_address)

	http.ListenAndServe(s.listen_address, nil)

	s.workerPool.Wait()
}

type apiFunc func(http.ResponseWriter, *http.Request) error

type ApiError struct {
	Error string `json:"error"`
}

func makeHTTPHandleFunc(f apiFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := f(w, r); err != nil {
			WriteJSON(w, http.StatusBadRequest, ApiError{Error: err.Error()})
		}
	}
}

func WriteJSON(w http.ResponseWriter, status int, v any) error {
	w.Header().Add("Content-Type", "application/json")
	w.WriteHeader(status)

	return json.NewEncoder(w).Encode(v)
}
