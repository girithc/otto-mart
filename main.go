package main

import (
	"fmt"
	"log"
	"pronto-go/api"
	"pronto-go/store"
	"pronto-go/worker"

	iam "google.golang.org/api/iam/v1"
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



func main() {
    
    fmt.Printf("Starting Pronto-DB\n\n")
    

    workerPool := worker.NewWorkerPool(10) 

    store, err := store.NewPostgresStore()

	if err != nil {
		log.Fatal(err)
	} 
    if err := store.Init(); err != nil {
		log.Fatal(err)
	} else {
        fmt.Println("Store.Init() is successful.")
    }
    server := api.NewServer(":3000", store, workerPool)
    
    //google_server := api.NewGoogleServer("pronto-bucket", "service-account")
    //fmt.Println("Created Google Server")
    //server.Run(google_server)

    server.Run()
}
 
func CheckError(err error) {
    if err != nil {
        panic(err)
    }
}