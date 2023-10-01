package main

import (
	"fmt"
	"log"
	"os"

	"github.com/girithc/pronto-go/api"
	"github.com/girithc/pronto-go/store"
	"github.com/girithc/pronto-go/worker"
)

func main() {
	fmt.Printf("Starting Pronto-DB\n\n")

	workerPool := worker.NewWorkerPool(10)

	store, cleanup := store.NewPostgresStore()

	defer cleanup()

	if err := store.Init(); err != nil {
		log.Fatal(err)
	} else {
		fmt.Println("Store.Init() is successful.")
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	server := api.NewServer(":"+port, store, workerPool)
	server.Run()
}

func CheckError(err error) {
	if err != nil {
		panic(err)
	}
}
