package api

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"time"

	"cloud.google.com/go/storage"
	"github.com/google/uuid"
	"google.golang.org/api/iam/v1"
)

func (gs *GoogleServer) handleGoogleSignManager(w http.ResponseWriter, r *http.Request) {
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
    fmt.Println("Content-Type ", ct)

    // Generates an object key for use in new Cloud Storage Object.
    // It's not duplicate with any object keys because of UUID.
    key := uuid.New().String()
    if ext := r.FormValue("ext"); ext != "" {
            key += fmt.Sprintf(".%s", ext)
    }

    // Generates a signed URL for use in the PUT request to GCS.
    // Generated URL should be expired after 15 mins.
    url, err := storage.SignedURL(gs.bucket, key, &storage.SignedURLOptions{
            GoogleAccessID: gs.service_account,
            Method:         "PUT",
            Expires:        time.Now().Add(15 * time.Minute),
            ContentType:    ct,
            // To avoid management for private key, use SignBytes instead of PrivateKey.
            // In this example, we are using the `iam.serviceAccounts.signBlob` API for signing bytes.
            // If you hope to avoid API call for signing bytes every time,
            // you can use self hosted private key and pass it in Privatekey.
            SignBytes: func(b []byte) ([]byte, error) {
                    resp, err := gs.iam_service.Projects.ServiceAccounts.SignBlob(
                            gs.service_account_id,
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
