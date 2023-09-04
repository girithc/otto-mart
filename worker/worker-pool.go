package worker

import (
	"fmt"
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

func (wp *WorkerPool) StartWorker(task func() error, resultCallback func(error)) {
    wp.workers <- struct{}{}
    wp.wg.Add(1)

    // Assign a unique worker ID
    workerID := len(wp.workers)

    fmt.Printf("Worker %d started\n", workerID)

    go func() {
        defer wp.wg.Done()
        defer func() {
            <-wp.workers
            fmt.Printf("Worker %d ended\n", workerID)
        }()
        err := task()
        resultCallback(err) // Pass the result to the callback function
    }()
}




func (wp *WorkerPool) Wait() {
	wp.wg.Wait()
}

