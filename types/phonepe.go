package types

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
