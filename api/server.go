package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"pronto-go/store"

	iam "google.golang.org/api/iam/v1"
	"google.golang.org/api/option"
)

type Server struct {
	listen_address string
	store *store.PostgresStore
}

func NewServer(listen_address string, store *store.PostgresStore) *Server {
	return &Server{
		listen_address: listen_address,
		store: store,
	}
}

type GoogleServer struct {
	bucket string
	service_account string
	service_account_id string
	iam_service *iam.Service
}

func NewGoogleServer(bucket string, service_account string) *GoogleServer {

	fmt.Println("Creating Google Server")

	ctx := context.Background()
	
	iamService, err := iam.NewService(ctx, option.WithCredentialsFile("./named-totality-296407-5646d400bb37.json"))
    fmt.Printf("iamService: %v\n", iamService)
	if err != nil {
        log.Fatal("iam.Server Error", err)
    }

	serviceAccountID := "service-account@named-totality-296407.iam.gserviceaccount.com"
	
	return &GoogleServer{
		bucket: bucket,
		service_account: service_account,
		service_account_id: serviceAccountID,
		iam_service: iamService,
	}
}

func (s *Server) Run(gs *GoogleServer) {

	http.HandleFunc("/gcloud/sign", gs.handleGoogleSignManager)

	http.HandleFunc("/store/available", makeHTTPHandleFunc(s.handleStoreClient))
	http.HandleFunc("/store", makeHTTPHandleFunc(s.handleStoreManager))

	http.HandleFunc("/higher-level-category", makeHTTPHandleFunc(s.handleHigherLevelCategory))
	
	http.HandleFunc("/category-higher-level-mapping", makeHTTPHandleFunc(s.handleCategoryHigherLevelMapping))

	http.HandleFunc("/category", makeHTTPHandleFunc(s.handleCategory))
	http.HandleFunc("/item", makeHTTPHandleFunc(s.handleItem))

	fmt.Println("Listening PORT", s.listen_address)

	http.ListenAndServe(s.listen_address, nil)
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




