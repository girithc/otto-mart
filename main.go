package main

import (
	"fmt"
	"log"

	"pronto-go/api"
	"pronto-go/store"
	"pronto-go/worker"
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

	// google_server := api.NewGoogleServer("pronto-bucket", "service-account")
	// fmt.Println("Created Google Server")
	// server.Run(google_server)

	server.Run()
}

func CheckError(err error) {
	if err != nil {
		panic(err)
	}
}
