package types

import (
	"time"

	"github.com/google/uuid"
)

type ManagerData struct {
	ID         int       `json:"id"`         // Manager's unique identifier
	Name       string    `json:"name"`       // Manager's name
	Phone      string    `json:"phone"`      // Manager's phone number, must be unique
	Token      uuid.UUID `json:"token"`      // Authentication token for the manager
	Created_At time.Time `json:"created_at"` // Timestamp of when the manager was added to the system
}

type ManagerLogin struct {
	Message string `json:"message"`
	Type    string `json:"type"`
	Manager ManagerData
}

type ManagerFCM struct {
	Phone string `json:"phone"`
	FCM   string `json:"fcm"`
}
