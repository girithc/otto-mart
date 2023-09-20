package worker

import (
	"log"
	"sync"
)

type Result struct {
	Error error
}

type Task func() Result

type WorkerPool struct {
	workers   chan struct{}
	wg        sync.WaitGroup
	workerID  int
	mu        sync.Mutex
}

func NewWorkerPool(workerCount int) *WorkerPool {
	return &WorkerPool{
		workers: make(chan struct{}, workerCount),
	}
}

func (wp *WorkerPool) StartWorker(task Task, callback func(Result)) {
	wp.workers <- struct{}{}
	wp.wg.Add(1)

	wp.mu.Lock()
	wp.workerID++
	workerID := wp.workerID
	wp.mu.Unlock()

	log.Printf("Worker %d started\n", workerID)

	go func() {
		defer wp.wg.Done()
		defer func() {
			<-wp.workers
			log.Printf(" - Worker %d ended\n", workerID)
		}()
		res := task()
		callback(res)
	}()
}

func (wp *WorkerPool) Wait() {
	wp.wg.Wait()
}
