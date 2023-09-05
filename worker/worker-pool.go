package worker

import (
	"fmt"
	"sync"
)

type WorkerPool struct {
    workerCount int
    workers     chan struct{}
    wg          sync.WaitGroup
    mu          sync.Mutex
    workerID    int // Add a unique worker ID counter
}

func NewWorkerPool(workerCount int) *WorkerPool {
    return &WorkerPool{
        workerCount: workerCount,
        workers:     make(chan struct{}, workerCount),
        workerID:    0, // Initialize worker ID counter
    }
}

func (wp *WorkerPool) StartWorker(task func() error, resultCallback func(error)) {
    wp.workers <- struct{}{}
    wp.wg.Add(1)

    wp.mu.Lock()
    wp.workerID++ // Increment the worker ID counter
    workerID := wp.workerID
    wp.mu.Unlock()

    fmt.Printf("Worker %d started\n", workerID)

    go func() {
        defer wp.wg.Done()
        defer func() {
            <-wp.workers
            fmt.Printf(" - Worker %d ended\n", workerID)
        }()
        err := task()
        resultCallback(err) // Pass the result to the callback function
    }()
}

func (wp *WorkerPool) Wait() {
    wp.wg.Wait()
}
