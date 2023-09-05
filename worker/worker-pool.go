package worker

import (
	"fmt"
	"net/http"
	"sync"
	"time"
)

type WorkerPool struct {
    workerCount int
    workers     chan struct{}
    wg          sync.WaitGroup
    mu          sync.Mutex
    workerID    int // Add a unique worker ID counter
}

type Response struct {
    *http.Response
    err error
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

// Dispatcher for making HTTP GET requests
func (wp *WorkerPool) DispatchGETRequests(reqs int, maxConcurrent int, url string) (int64, int64, time.Duration) {
    reqChan := make(chan *http.Request)
    respChan := make(chan Response)
    start := time.Now()

    // Start the dispatcher and worker pool
    go wp.dispatcher(reqChan, reqs)
    go wp.workerPool(reqChan, respChan, maxConcurrent)

    // Consume responses
    conns, size := wp.consumer(respChan)

    took := time.Since(start)
    return conns, size, took
}

// Dispatcher
func (wp *WorkerPool) dispatcher(reqChan chan *http.Request, reqs int) {
    defer close(reqChan)
    for i := 0; i < reqs; i++ {
        req, err := http.NewRequest("GET", "http://localhost/", nil)
        if err != nil {
            fmt.Println(err)
        }
        reqChan <- req
    }
}

// Worker Pool
func (wp *WorkerPool) workerPool(reqChan chan *http.Request, respChan chan Response, maxConcurrent int) {
    t := &http.Transport{}
    for i := 0; i < maxConcurrent; i++ {
        go wp.worker(t, reqChan, respChan)
    }
}

// Worker
func (wp *WorkerPool) worker(t *http.Transport, reqChan chan *http.Request, respChan chan Response) {
    for req := range reqChan {
        resp, err := t.RoundTrip(req)
        r := Response{resp, err}
        respChan <- r
    }
}

// Consumer
func (wp *WorkerPool) consumer(respChan chan Response) (int64, int64) {
    var (
        conns int64
        size  int64
    )
    for conns < int64(wp.workerID) { // Use workerID as reqs
        select {
        case r, ok := <-respChan:
            if ok {
                if r.err != nil {
                    fmt.Println(r.err)
                } else {
                    size += r.ContentLength
                    if err := r.Body.Close(); err != nil {
                        fmt.Println(err)
                    }
                }
                conns++
            }
        }
    }
    return conns, size
}
