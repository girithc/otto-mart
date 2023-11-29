package types

import "encoding/json"

type PhonePeCartId struct {
	CartId int `json:"cart_id"`
}

type PhonePeInit struct {
	MerchantId            string            `json:"merchantId"`
	MerchantTransactionId string            `json:"merchantTransactionId"`
	MerchantUserId        string            `json:"merchantUserId"`
	Amount                int               `json:"amount"`
	RedirectUrl           string            `json:"redirectUrl"`
	RedirectMode          string            `json:"redirectMode"`
	CallbackUrl           string            `json:"callbackUrl"`
	MobileNumber          string            `json:"mobileNumber"`
	PaymentInstrument     PaymentInstrument `json:"paymentInstrument"`
}

type PaymentInstrument struct {
	Type string `json:"type"`
}

type PhonePeResponse struct {
	Success bool   `json:"success"`
	Code    string `json:"code"`
	Message string `json:"message"`
	Data    Data   `json:"data"`
}

type Data struct {
	MerchantId            string             `json:"merchantId"`
	MerchantTransactionId string             `json:"merchantTransactionId"`
	InstrumentResponse    InstrumentResponse `json:"instrumentResponse"`
}

type InstrumentResponse struct {
	Type         string       `json:"type"`
	RedirectInfo RedirectInfo `json:"redirectInfo"`
}

type RedirectInfo struct {
	URL    string `json:"url"`
	Method string `json:"method"`
}

type CallbackResponse struct {
	Response string `json:"response"`
}

type PaymentResponse struct {
	Success bool        `json:"success"`
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Data    PaymentData `json:"data"`
}

type PaymentData struct {
	MerchantId            string          `json:"merchantId"`
	MerchantTransactionId string          `json:"merchantTransactionId"`
	TransactionId         string          `json:"transactionId"`
	Amount                float64         `json:"amount"`
	State                 string          `json:"state"`
	ResponseCode          string          `json:"responseCode"`
	PaymentInstrument     json.RawMessage `json:"paymentInstrument"`
}

type UPIPaymentInstrument struct {
	Type string `json:"type"`
	UTR  string `json:"utr"`
}

type CardPaymentInstrument struct {
	Type                string `json:"type"`
	CardType            string `json:"cardType"`
	PgTransactionId     string `json:"pgTransactionId"`
	BankTransactionId   string `json:"bankTransactionId"`
	PgAuthorizationCode string `json:"pgAuthorizationCode"`
	Arn                 string `json:"arn"`
	BankId              string `json:"bankId"`
}

type NetBankingPaymentInstrument struct {
	Type                   string `json:"type"`
	PgTransactionId        string `json:"pgTransactionId"`
	PgServiceTransactionId string `json:"pgServiceTransactionId"`
	BankTransactionId      string `json:"bankTransactionId"`
	BankId                 string `json:"bankId"`
}

// Define a struct to return the parsed data
type PaymentCallbackResult struct {
	PaymentResponse
	PaymentInstrument interface{}
}

type TempInstrumentType struct {
	Type string `json:"type"`
}
