package worker

import (
	"log"
	"sync"
	"time"
)

type Result struct {
	Error  error
	Output interface{}
}

type Task func() Result

type WorkerPool struct {
	workers   chan struct{}
	wg        sync.WaitGroup
	workerID  int
	mu        sync.Mutex
	taskLog   []TaskLog // A slice to store logs for monitoring purposes
}

type TaskLog struct {
	TaskID      int
	StartTime   time.Time
	EndTime     time.Time
	Status      string
	Error       error
	Output      interface{}
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
	logEntry := TaskLog{
		TaskID:    workerID,
		StartTime: time.Now(),
		Status:    "Started",
	}
	wp.taskLog = append(wp.taskLog, logEntry)
	wp.mu.Unlock()

	log.Printf("Worker %d started\n", workerID)

	go func() {
		defer wp.wg.Done()
		defer func() {
			<-wp.workers

			// Update the task log for the completed task
			wp.mu.Lock()
			for i := range wp.taskLog {
				if wp.taskLog[i].TaskID == workerID {
					wp.taskLog[i].EndTime = time.Now()
					wp.taskLog[i].Status = "Completed"
					break
				}
			}
			wp.mu.Unlock()

			log.Printf(" - Worker %d ended\n", workerID)
		}()
		res := task()
		callback(res)
	}()
}

func (wp *WorkerPool) Wait() {
	wp.wg.Wait()
}

// This function allows us to retrieve task logs for monitoring
func (wp *WorkerPool) GetTaskLogs() []TaskLog {
	return wp.taskLog
}
