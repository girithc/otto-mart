package worker

import (
	"fmt"
	"net/http"
	"sync"
)

type WorkerPool struct {
	workerCount int
	workers     chan struct{}
	wg          sync.WaitGroup
}

func NewWorkerPool(workerCount int) *WorkerPool {
	return &WorkerPool{
		workerCount: workerCount,
		workers:     make(chan struct{}, workerCount),
	}
}

func (wp *WorkerPool) StartWorker(task func()) {
	wp.workers <- struct{}{}
	wp.wg.Add(1)

	go func() {
		defer wp.wg.Done()
		defer func() { <-wp.workers }()
		task()
	}()
}

func (wp *WorkerPool) Wait() {
	wp.wg.Wait()
}

func main() {
	
	// Create a worker pool with a specific number of workers
	workerPool := NewWorkerPool(10)

	http.HandleFunc("/process", func(w http.ResponseWriter, r *http.Request) {
		// Define the task you want to perform concurrently
		task := func() {
			// Perform the task here
			fmt.Println("Processing task...")
		}

		// Start the task in a worker goroutine
		workerPool.StartWorker(task)

		// Respond to the client
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Task submitted for processing"))
	})

	server := http.Server{
		Addr: ":8080",
	}

	go func() {
		_ = server.ListenAndServe()
	}()

	fmt.Println("Server started on :8080")

	// Wait for all tasks to finish before exiting
	workerPool.Wait()
}
