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

	http.HandleFunc("/get-category", makeHTTPHandleFunc(s.handleGetCategory))
	http.HandleFunc("/get-brand", makeHTTPHandleFunc(s.handleGetBrand))

	http.HandleFunc("/item-store", makeHTTPHandleFunc(s.handleItemStore))
	http.HandleFunc("/item-update", makeHTTPHandleFunc(s.handleItemUpdate))
	http.HandleFunc("/item-add-stock", makeHTTPHandleFunc(s.handleItemAddStock))
	http.HandleFunc("/item", makeHTTPHandleFunc(s.handleItem))
	http.HandleFunc("/search-item", makeHTTPHandleFunc(s.handleSearchItem))
	http.HandleFunc("/item-add-quick", makeHTTPHandleFunc(s.handleItemAddQuick))

	http.HandleFunc("/customer", makeHTTPHandleFunc(s.handleCustomer))
	http.HandleFunc("/login-customer", makeHTTPHandleFunc(s.handleLoginCustomer))
	http.HandleFunc("/login-packer", makeHTTPHandleFunc(s.handleLoginPacker))
	http.HandleFunc("/shopping-cart", makeHTTPHandleFunc(s.handleShoppingCart))
	http.HandleFunc("/cart-item", makeHTTPHandleFunc(s.handleCartItem))

	http.HandleFunc("/checkout-lock-items", makeHTTPHandleFunc(s.handleCheckoutLockItems))
	http.HandleFunc("/checkout-payment", makeHTTPHandleFunc(s.handleCheckoutPayment))
	http.HandleFunc("/checkout-cancel", makeHTTPHandleFunc(s.handleCancelCheckout))

	http.HandleFunc("/packer-pack-order", makeHTTPHandleFunc(s.handlePackerPackOrder))
	http.HandleFunc("/packer-fetch-item", makeHTTPHandleFunc(s.handlePackerFetchItem))
	http.HandleFunc("/packer-get-items", makeHTTPHandleFunc(s.handlePackerGetAllItems))
	http.HandleFunc("/packer-pack-item", makeHTTPHandleFunc(s.handlePackerPackItem))
	http.HandleFunc("/packer-cancel-order", makeHTTPHandleFunc(s.handlePackerCancelOrder))

	http.HandleFunc("/packer-space-order", makeHTTPHandleFunc(s.handlePackerAllocateSpace))

	http.HandleFunc("/delivery-partner", makeHTTPHandleFunc(s.handleDeliveryPartner))
	http.HandleFunc("/delivery-partner-login", makeHTTPHandleFunc(s.handleDeliveryPartnerLogin))
	http.HandleFunc("/delivery-partner-check-order", makeHTTPHandleFunc(s.handleDeliveryPartnerCheckOrder))
	http.HandleFunc("/delivery-partner-accept-order", makeHTTPHandleFunc(s.handleDeliveryPartnerAcceptOrder))
	http.HandleFunc("/delivery-partner-pickup-order", makeHTTPHandleFunc(s.handleDeliveryPartnerPickupOrder))
	http.HandleFunc("/delivery-partner-dispatch-order", makeHTTPHandleFunc(s.handleDeliveryPartnerDispatchOrder))

	http.HandleFunc("/address", makeHTTPHandleFunc(s.handleAddress))
	http.HandleFunc("/deliver-to", makeHTTPHandleFunc(s.handleDeliverTo))

	http.HandleFunc("/brand", makeHTTPHandleFunc(s.handleBrand))

	http.HandleFunc("/store-sales-order", makeHTTPHandleFunc(s.handleStoreSalesOrder))
	http.HandleFunc("/sales-order-store", makeHTTPHandleFunc(s.handleSalesOrderStore))
	http.HandleFunc("/sales-order-details", makeHTTPHandleFunc(s.handleSalesOrderDetails))
	http.HandleFunc("/sales-order", makeHTTPHandleFunc(s.handleSalesOrder))

	http.HandleFunc("/phonepe-payment-init", makeHTTPHandleFunc(s.handlePhonePe))
	http.HandleFunc("/phonepe-callback", makeHTTPHandleFunc(s.handlePhonePeCallback))
	http.HandleFunc("/phonepe-check-status", makeHTTPHandleFunc(s.handlePhonePeVerifyPayment))

	http.HandleFunc("/payment-verify", makeHTTPHandleFunc(s.handlePaymentVerify))

	http.HandleFunc("/send-otp", makeHTTPHandleFunc(s.handleSendOtp))
	http.HandleFunc("/verify-otp", makeHTTPHandleFunc(s.handleVerifyOtp))

	http.HandleFunc("/shelf-crud", makeHTTPHandleFunc(s.handleShelfCRUD))
	http.Handle("/lock-stock", makeHTTPHandleFunc(s.handleLockStock))
	// Planner
	// http.HandleFunc("/plan-add-item", makeHTTPHandleFunc(s.handleAddItemList))

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
