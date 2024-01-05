package api

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type CloudTaskPayload struct {
	CartID   int    `json:"cart_id"`
	LockType string `json:"lock_type"`
}

func (s *Server) HandlePOSTCloudTask(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered HandlePOSTCloudTask")

	// Read and parse the request body
	var payload CloudTaskPayload
	err := json.NewDecoder(req.Body).Decode(&payload)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, map[string]string{"error": "invalid JSON payload"})
	}
	defer req.Body.Close()

	// Use payload.CartID and payload.LockType as needed
	fmt.Printf("Received Cloud Task with Cart ID: %d and Lock Type: %s\n", payload.CartID, payload.LockType)

	// Your existing logic
	err = s.store.CreateCloudTask() // Update this call if needed to pass payload
	if err != nil {
		return WriteJSON(res, http.StatusInternalServerError, nil)
	}
	return WriteJSON(res, http.StatusOK, nil)
}
