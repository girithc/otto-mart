package types

import (
	"time"

	"github.com/google/uuid"
)

type SendOTPResponse struct {
	RequestId string `json:"request_id"`
	Type      string `json:"type"`
}

type VerifyOTPResponse struct {
	Message string `json:"message"`
	Type    string `json:"type"`
}

type CustomerLogin struct {
	Message  string `json:"message"`
	Type     string `json:"type"`
	Customer Customer_Login
}

type MobileOtp struct {
	Phone string `json:"phone"`
	Otp   int    `json:"otp"`
	FCM   string `json:"fcm"`
}

// Basic
type Customer struct {
	ID             int       `json:"id"`
	Name           string    `json:"name"`
	Phone          int       `json:"phone"`
	Address        string    `json:"address"`
	MerchantUserID string    `json:"merchant_user_id"`
	Created_At     time.Time `json:"created_at"`
}

type Customer_Login struct {
	ID             int       `json:"id"`
	Name           string    `json:"name"`
	Phone          string    `json:"phone"`
	Address        string    `json:"address"`
	MerchantUserID string    `json:"merchant_user_id"`
	Created_At     time.Time `json:"created_at"`
	Token          uuid.UUID `json:"token"`
}

type Create_Customer struct {
	Phone string `json:"phone"`
}

type CustomerFCM struct {
	Phone string `json:"phone"`
	FCM   string `json:"fcm"`
}

type Update_Customer struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Phone   int    `json:"phone"`
	Address string `json:"address"`
}

type Delete_User struct {
	ID    int `json:"id"`
	Phone int `json:"phone"`
}

func New_Customer(phone string) (*Create_Customer, error) {
	return &Create_Customer{
		Phone: phone,
	}, nil
}

func New_Update_Customer(id int, name string, phone int, address string) (*Update_Customer, error) {
	return &Update_Customer{
		ID:      id,
		Name:    name,
		Phone:   phone,
		Address: address,
	}, nil
}

type AutoLogin struct {
	Name    string    `json:"name"`
	Phone   string    `json:"phone"`
	Address string    `json:"address"`
	Id      int       `json:"id"`
	Token   uuid.UUID `json:"token"`
}
