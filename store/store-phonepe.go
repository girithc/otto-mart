package store

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) PhonePePaymentCallback(response string) (*types.PaymentCallbackResult, error) {
	// Decode the base64 encoded response
	decoded, err := base64.StdEncoding.DecodeString(response)
	if err != nil {
		fmt.Printf("Error decoding base64 string: %v\n", err)
		return nil, err
	}

	// Unmarshal the JSON into the PaymentResponse struct
	var paymentResponse types.PaymentResponse
	err = json.Unmarshal(decoded, &paymentResponse)
	if err != nil {
		fmt.Printf("Error unmarshalling JSON: %v\n", err)
		return nil, err
	}

	// Temporary struct to extract the instrument type
	type TempInstrumentType struct {
		Type string `json:"type"`
	}
	var tempInstrument TempInstrumentType
	err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &tempInstrument)
	if err != nil {
		fmt.Printf("Error unmarshalling instrument type: %v\n", err)
		return nil, err
	}
	instrumentType := tempInstrument.Type
	fmt.Printf("InstrumentType: %s\n", instrumentType)

	result := &types.PaymentCallbackResult{
		PaymentResponse: paymentResponse,
	}

	// Determine the type of payment instrument and unmarshal accordingly
	switch instrumentType {
	case "UPI":
		var upi types.UPIPaymentInstrument
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &upi)
		if err != nil {
			fmt.Printf("Error unmarshalling UPI payment instrument: %v\n", err)
			return nil, err
		}
		result.PaymentInstrument = upi
	case "CARD": // Assuming "CARD"  is the type for credit/debit cards
		var card types.CardPaymentInstrument
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &card)
		if err != nil {
			fmt.Printf("Error unmarshalling CARD payment instrument: %v\n", err)
			return nil, err
		}
		result.PaymentInstrument = card
	case "NETBANKING": // Assuming "NETBANKING" is the type for net banking
		var netBanking types.NetBankingPaymentInstrument
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &netBanking)
		if err != nil {
			fmt.Printf("Error unmarshalling NETBANKING payment instrument: %v\n", err)
			return nil, err
		}
		result.PaymentInstrument = netBanking
	default:
		return nil, fmt.Errorf("unknown payment instrument type: %s", instrumentType)
	}

	if err != nil {
		return nil, err
	}

	return result, nil
}

func (s *PostgresStore) PhonePePaymentComplete(cart_id int) error {
	return nil
}

func (s *PostgresStore) PhonePePaymentInit(cart_id int) (*types.PhonePeResponse, error) {
	// Hardcoded values for PhonePeInit
	phonepe := &types.PhonePeInit{
		MerchantId:            "PGTESTPAYUAT",
		MerchantTransactionId: "MT7850590068188104",
		MerchantUserId:        "MUID123",
		Amount:                10000,
		RedirectUrl:           "https://youtube.com/redirect-url",
		RedirectMode:          "REDIRECT",
		CallbackUrl:           "https://pronto-go-3ogvsx3vlq-el.a.run.app/phonepe-callback",
		MobileNumber:          "9999999999",
		PaymentInstrument:     types.PaymentInstrument{Type: "PAY_PAGE"},
	}

	// Salt key and other configurations
	saltKey := "099eb0cd-02cf-4e2a-8aca-3e6c6aff0399"
	saltIndex := "1"

	// Convert payload to JSON
	payloadJson, err := json.Marshal(phonepe)
	if err != nil {
		return nil, err
	}

	// Base64 encode the payload
	encodedPayload := base64.StdEncoding.EncodeToString(payloadJson)

	// Calculate X-VERIFY Checksum
	checksumData := fmt.Sprintf("%s/pg/v1/pay%s", encodedPayload, saltKey)
	checksum := sha256.Sum256([]byte(checksumData))
	xVerify := fmt.Sprintf("%x###%s", checksum, saltIndex)

	// Prepare the request
	requestPayload := []byte(fmt.Sprintf(`{"request":"%s"}`, encodedPayload))
	req, err := http.NewRequest("POST", "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/pay", bytes.NewBuffer(requestPayload))
	if err != nil {
		return nil, err
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-VERIFY", xVerify)

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// Read the response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// Unmarshal the response into PhonePeResponse struct
	var response types.PhonePeResponse
	err = json.Unmarshal(body, &response)
	if err != nil {
		return nil, err
	}

	// successful in initiating PhonePe Payment
	// generated response url

	// reset timer
	err = s.InitiatePayment(cart_id)
	if err != nil {
		return nil, err
	}

	return &response, nil
}

func (s *PostgresStore) InitiatePayment(cart_id int) error {
	// Cancel the existing context if it exists
	if cancel, exists := s.cancelFuncs[cart_id]; exists {
		s.lockExtended[cart_id] = true
		cancel()
		delete(s.cancelFuncs, cart_id)
	} else {
		// If no context exists, it might indicate an issue, handle it as needed
		return fmt.Errorf("no active context for cart this might indicate a problem")
	}

	// Set a new timeout duration for the payment process
	timeoutDuration := 9 * time.Minute
	ctx, cancel := context.WithTimeout(context.Background(), timeoutDuration)

	// Store the new cancel function
	s.cancelFuncs[cart_id] = cancel
	s.paymentStatus[cart_id] = false

	// Launch a new goroutine for the new context
	go func() {
		<-ctx.Done()
		if ctx.Err() == context.DeadlineExceeded {
			// Timeout exceeded, reset quantities
			fmt.Println("Payment was not completed in time. Resetting quantities...")
			s.ResetLockedQuantities(cart_id)

			// Clean up
			delete(s.cancelFuncs, cart_id)
			delete(s.lockExtended, cart_id)
			delete(s.paymentStatus, cart_id)

			// Context Cancelled. Payment completed. S2S call completed.
		} else if paymentMade, exists := s.paymentStatus[cart_id]; exists {

			if paymentMade {
				fmt.Print("S2S Callback received.")
				// s.MakeQuantitiesPermanent(cart_id)
			} else {
				fmt.Print("Payment not made. Or. Payment was not successful.")
				s.ResetLockedQuantities(cart_id)
			}

			// Clean up
			delete(s.cancelFuncs, cart_id)
			delete(s.lockExtended, cart_id)
			delete(s.paymentStatus, cart_id)
		} else {
			// Payment process has either moved forward or an error occurred
			fmt.Println("Cancelled-PhonePe-Checkout")
			s.ResetLockedQuantities(cart_id)

			delete(s.cancelFuncs, cart_id)
			delete(s.lockExtended, cart_id)
			delete(s.paymentStatus, cart_id)

		}
		// Clean up the cancel function
	}()

	return nil
}
