package main

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"pronto-go/api"
	"pronto-go/store"
	"time"

	"github.com/google/uuid"
	iam "google.golang.org/api/iam/v1"

	"cloud.google.com/go/storage"
)

var (
    // iamService is a client for calling the signBlob API.
    iamService *iam.Service

    // serviceAccountName represents Service Account Name.
    // See more details: https://cloud.google.com/iam/docs/service-accounts
    serviceAccountName string

    // serviceAccountID follows the below format.
    // "projects/%s/serviceAccounts/%s"
    serviceAccountID string

    // uploadableBucket is the destination bucket.
    // All users will upload files directly to this bucket by using generated Signed URL.
    uploadableBucket string
)

func signHandler(w http.ResponseWriter, r *http.Request) {
    // Accepts only POST method.
    // Otherwise, this handler returns 405.
    if r.Method != "POST" {
            w.Header().Set("Allow", "POST")
            http.Error(w, "Only POST is supported", http.StatusMethodNotAllowed)
            return
    }

    ct := r.FormValue("content_type")
    if ct == "" {
            http.Error(w, "content_type must be set", http.StatusBadRequest)
            return
    }

    // Generates an object key for use in new Cloud Storage Object.
    // It's not duplicate with any object keys because of UUID.
    key := uuid.New().String()
    if ext := r.FormValue("ext"); ext != "" {
            key += fmt.Sprintf(".%s", ext)
    }

    // Generates a signed URL for use in the PUT request to GCS.
    // Generated URL should be expired after 15 mins.
    url, err := storage.SignedURL(uploadableBucket, key, &storage.SignedURLOptions{
            GoogleAccessID: serviceAccountName,
            Method:         "PUT",
            Expires:        time.Now().Add(15 * time.Minute),
            ContentType:    ct,
            // To avoid management for private key, use SignBytes instead of PrivateKey.
            // In this example, we are using the `iam.serviceAccounts.signBlob` API for signing bytes.
            // If you hope to avoid API call for signing bytes every time,
            // you can use self hosted private key and pass it in Privatekey.
            SignBytes: func(b []byte) ([]byte, error) {
                    resp, err := iamService.Projects.ServiceAccounts.SignBlob(
                            serviceAccountID,
                            &iam.SignBlobRequest{BytesToSign: base64.StdEncoding.EncodeToString(b)},
                    ).Context(r.Context()).Do()
                    if err != nil {
                            return nil, err
                    }
                    return base64.StdEncoding.DecodeString(resp.Signature)
            },
    })
    if err != nil {
            log.Printf("sign: failed to sign, err = %v\n", err)
            http.Error(w, "failed to sign by internal server error", http.StatusInternalServerError)
            return
    }
    w.WriteHeader(http.StatusOK)
    fmt.Fprintln(w, url)
}

 

func main() {
    
    fmt.Printf("Starting Pronto-DB\n\n")
    store, err := store.NewPostgresStore()

	if err != nil {
		log.Fatal(err)
	} 
    if err := store.Init(); err != nil {
		log.Fatal(err)
	} else {
        fmt.Println("Store.Init() is successful.")
    }
    server := api.NewServer(":3000", store)
    
    google_server := api.NewGoogleServer("pronto-bucket", "service-account")
    fmt.Println("Created Google Server")
    server.Run(google_server)
}
 
func CheckError(err error) {
    if err != nil {
        panic(err)
    }
}