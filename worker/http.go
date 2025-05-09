package worker

import (
	"io"
	"log"
	"net/http"
	"time"
)

type CustomRequest struct {
	Method  string
	URL     string
	Body    io.Reader
	Headers map[string]string
}

type HTTPResponse struct {
	*http.Response
	err error
}

func DispatchRequests(wp *WorkerPool, requests []CustomRequest) {
	reqChan := make(chan *http.Request, len(requests))
	respChan := make(chan HTTPResponse, len(requests))

	t := &http.Transport{}
	client := &http.Client{
		Transport: t,
		Timeout:   10 * time.Second, // timeout for the client
	}

	for _, customReq := range requests {
		req, err := http.NewRequest(customReq.Method, customReq.URL, customReq.Body)
		if err != nil {
			log.Println(err)
			continue
		}

		// Setting headers if provided
		for key, value := range customReq.Headers {
			req.Header.Set(key, value)
		}

		reqChan <- req
	}

	close(reqChan)

	for req := range reqChan {
		wp.StartWorker(func() Result {
			resp, err := client.Do(req)
			if err != nil {
				return Result{Error: err}
			}
			respChan <- HTTPResponse{resp, err}
			closeErr := resp.Body.Close()
			if closeErr != nil {
				return Result{Error: closeErr}
			}
			return Result{}
		}, func(res Result) {
			if res.Error != nil {
				log.Println("Worker error:", res.Error)
			}
		})
	}

	go func() {
		wp.Wait()
		close(respChan)
	}()

	for response := range respChan {
		if response.err != nil {
			log.Println("Request error:", response.err)
		} else {
			// Process the response as needed
		}
	}
}
