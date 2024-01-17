package store

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	cloudtasks "cloud.google.com/go/cloudtasks/apiv2"
	taskspb "cloud.google.com/go/cloudtasks/apiv2/cloudtaskspb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func createHTTPTaskWithToken(projectID, locationID, queueID, url, email string, payload interface{}, delayTime int) (*taskspb.Task, error) {
	// Create a new Cloud Tasks client instance.
	ctx := context.Background()
	client, err := cloudtasks.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("NewClient: %w", err)
	}
	defer client.Close()

	// Build the Task queue path.
	queuePath := fmt.Sprintf("projects/%s/locations/%s/queues/%s", projectID, locationID, queueID)

	scheduleTime := time.Now().Add(time.Minute * time.Duration(delayTime))

	// Convert payload to JSON
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("json.Marshal: %w", err)
	}

	// Build the Task payload.
	req := &taskspb.CreateTaskRequest{
		Parent: queuePath,
		Task: &taskspb.Task{
			MessageType: &taskspb.Task_HttpRequest{
				HttpRequest: &taskspb.HttpRequest{
					HttpMethod: taskspb.HttpMethod_POST,
					Url:        url,
					AuthorizationHeader: &taskspb.HttpRequest_OidcToken{
						OidcToken: &taskspb.OidcToken{
							ServiceAccountEmail: email,
						},
					},
					Body: jsonPayload,
				},
			},
			// Set schedule time
			ScheduleTime: timestamppb.New(scheduleTime),
		},
	}

	// Create the task.
	createdTask, err := client.CreateTask(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("cloudtasks.CreateTask: %w", err)
	}

	return createdTask, nil
}

func (s *PostgresStore) CreateCloudTask(cartID int, lockType string, sign string, merchantTransactionID string) error {
	email := "admin-service-account@seismic-ground-410711.iam.gserviceaccount.com"

	var delayTime int

	if lockType == "lock-stock" {
		delayTime = 1

		// Prepare the payload
		payload := map[string]interface{}{
			"cart_id":               cartID,
			"lock_type":             lockType,
			"sign":                  sign,
			"merchantTransactionId": merchantTransactionID,
		}

		// Create Task with Token and JSON payload
		if task, err := createHTTPTaskWithToken("seismic-ground-410711", "asia-south1", "lock-stock", "https://otto-mart-2cta4tgbnq-el.a.run.app/lock-stock", email, payload, delayTime); err != nil {
			fmt.Printf("Failed to create Task with token: %v\n", err)
		} else {
			fmt.Println("Task with token created successfully", task.GetName())
		}
	} else if lockType == "lock-stock-pay" {
		delayTime = 9

		// Prepare the payload
		payload := map[string]interface{}{
			"cart_id":   cartID,
			"lock_type": lockType,
			"sign":      sign,
		}

		// Create Task with Token and JSON payload
		if task, err := createHTTPTaskWithToken("seismic-ground-410711", "asia-south1", "lock-stock", "https://otto-mart-2cta4tgbnq-el.a.run.app/lock-stock", email, payload, delayTime); err != nil {
			fmt.Printf("Failed to create Task with token: %v\n", err)
		} else {
			fmt.Println("Task with token created successfully", task.GetName())
		}
	}

	return nil
}
