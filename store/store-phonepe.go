package store

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) PhonePeCheckStatus(cart_id int, return_status bool) (bool, error) {
	// check for s2s callback
	// if received and paid
	// success
	// if received and failed
	// payment fail
	// if not received
	// send check status api
	// repeat the process

	//if status pending
	//follow guidelines.
	/*
		Check Status API - Reconciliation [MANDATORY]
		If the payment status is Pending, then Check Status API should be called in the following interval:
		The first status check at 20-25 seconds post transaction start, then
		Every 3 seconds once for the next 30 seconds,
		Every 6 seconds once for the next 60 seconds,
		Every 10 seconds for the next 60 seconds,
		Every 30 seconds for the next 60 seconds, and then
		Every 1 min until timeout (20 mins).
	*/

	transaction, err := s.GetTransactionByCartId(cart_id)
	if err != nil {
		return false, fmt.Errorf("error fetching transaction: %w", err)
	}

	// Check if S2S callback has been received
	if transaction.ResponseCode != "" {
		// Check if payment was successful or failed
		if return_status {
			return transaction.ResponseCode == "SUCCESS", nil
		}
	}

	// If S2S callback not received, call Check Status API
	success, err := s.CallCheckStatusAPI(transaction.MerchantId, transaction.MerchantTransactionId)
	if err != nil {
		return false, err
	}

	return success, nil
}

func (s *PostgresStore) GetTransactionByCartId(cart_id int) (*types.Transaction, error) {
	var transaction types.Transaction
	query := "SELECT merchant_transaction_id, merchant_id, response_code FROM transaction WHERE cart_id = $1"
	err := s.db.QueryRow(query, cart_id).Scan(&transaction.MerchantTransactionId, &transaction.MerchantId, &transaction.ResponseCode)
	if err != nil {
		return nil, err
	}
	return &transaction, nil
}

func (s *PostgresStore) CallCheckStatusAPI(merchantId, merchantTransactionId string) (bool, error) {
	// Construct the URL
	fmt.Println("Entered CallCheckStatusAPI")
	url := fmt.Sprintf("https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/%s/%s", merchantId, merchantTransactionId)

	// Create the request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Println("Error creating request:", err)
		return false, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-VERIFY", GenerateXVerify(merchantId, merchantTransactionId))
	req.Header.Set("X-MERCHANT-ID", merchantId)

	// Execute the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error executing request:", err)
		return false, err
	}
	defer resp.Body.Close()

	// Read and print the response body
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		return false, err
	}
	bodyString := string(bodyBytes)
	fmt.Println("Response Body:", bodyString)

	// Parse the response
	var response struct {
		Success bool `json:"success"`
		Data    struct {
			MerchantTransactionId string `json:"merchantTransactionId"`
			State                 string `json:"state"`
			Amount                int    `json:"amount"`
		} `json:"data"`
	}
	err = json.Unmarshal(bodyBytes, &response)
	if err != nil {
		fmt.Println("Error decoding response:", err)
		return false, err
	}

	fmt.Println("Check-Status-Response:", response.Data.Amount)
	return response.Data.State == "COMPLETED", nil
}

func GenerateXVerify(merchantId, merchantTransactionId string) string {
	// Concatenating the strings as per the requirement
	saltKey := "099eb0cd-02cf-4e2a-8aca-3e6c6aff0399"
	saltIndex := "1"
	concatenatedString := fmt.Sprintf("/pg/v1/status/%s/%s%s", merchantId, merchantTransactionId, saltKey)

	// Creating a SHA256 hash
	hasher := sha256.New()
	hasher.Write([]byte(concatenatedString))
	sha256Hash := hex.EncodeToString(hasher.Sum(nil))

	// Appending '###' and saltIndex
	xVerify := fmt.Sprintf("%s###%s", sha256Hash, saltIndex)

	return xVerify
}

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

	// Determine the type of payment instrument and unmarshal accordingly
	var paymentInstrument interface{}
	switch instrumentType {
	case "UPI":
		var upi types.UPIPaymentInstrument
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &upi)
		if err != nil {
			fmt.Printf("Error unmarshalling UPI payment instrument: %v\n", err)
			return nil, err
		}
		paymentInstrument = upi
	case "CARD": // Assuming "CARD"  is the type for credit/debit cards
		var card types.CardPaymentInstrument
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &card)
		if err != nil {
			fmt.Printf("Error unmarshalling CARD payment instrument: %v\n", err)
			return nil, err
		}
		paymentInstrument = card
	case "NETBANKING": // Assuming "NETBANKING" is the type for net banking
		var netBanking types.NetBankingPaymentInstrument
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &netBanking)
		if err != nil {
			fmt.Printf("Error unmarshalling NETBANKING payment instrument: %v\n", err)
			return nil, err
		}
		paymentInstrument = netBanking
	default:
		return nil, fmt.Errorf("unknown payment instrument type: %s", instrumentType)
	}

	/*
		paymentDetails, err := json.Marshal(paymentResponse.Data.PaymentInstrument) // Convert the whole response to JSON
		if err != nil {
			fmt.Printf("Error marshalling payment response: %v\n", err)
			return nil, err
		}
	*/

	// Prepare and execute the SQL update query
	updateQuery := `
    UPDATE transaction
    SET status = $1, 
        response_code = $2,
        payment_details = $3,
		payment_method = $4,
		merchant_id = $5,
		payment_gateway_name = $6
    WHERE merchant_transaction_id = $7`

	_, err = s.db.Exec(updateQuery, paymentResponse.Data.State, paymentResponse.Data.ResponseCode,
		paymentInstrument, instrumentType, paymentResponse.Data.MerchantId, "PhonePe", paymentResponse.Data.MerchantTransactionId)
	if err != nil {
		fmt.Printf("Error updating transaction record: %v\n", err)
		return nil, err
	}

	// Create the result struct
	result := &types.PaymentCallbackResult{
		PaymentResponse:   paymentResponse,
		PaymentInstrument: paymentInstrument,
	}

	return result, nil
}

func (s *PostgresStore) PhonePePaymentComplete(cart_id int) error {
	return nil
}

func (s *PostgresStore) PhonePePaymentInit(cart_id int) (*types.PhonePeResponse, error) {
	// Hardcoded values for PhonePeInit

	/*
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
	*/

	phonepe := &types.PhonePeInit{
		MerchantId:        "PGTESTPAYUAT",
		RedirectUrl:       "https://youtube.com/redirect-url",
		RedirectMode:      "REDIRECT",
		CallbackUrl:       "https://pronto-go-3ogvsx3vlq-el.a.run.app/phonepe-callback",
		PaymentInstrument: types.PaymentInstrument{Type: "PAY_PAGE"},
	}

	// Combined SQL query
	query := `
        SELECT 
            t.merchant_transaction_id, 
            c.merchant_user_id, 
			c.phone,
            sc.subtotal
        FROM 
            shopping_cart sc
        JOIN 
            customer c ON sc.customer_id = c.id
        JOIN 
            transaction t ON sc.id = t.cart_id
        WHERE 
            sc.id = $1
    `

	var amount int
	// Execute the query
	err := s.db.QueryRow(query, cart_id).Scan(&phonepe.MerchantTransactionId, &phonepe.MerchantUserId, &phonepe.MobileNumber, &amount)
	if err != nil {
		return nil, fmt.Errorf("error fetching data: %w", err)
	}

	phonepe.Amount = (100 * amount)

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
	body, err := io.ReadAll(resp.Body)
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
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %w", err)
	}

	// Check for an existing cart_lock record and update it
	query := `UPDATE cart_lock SET completed = 'success', last_updated = CURRENT_TIMESTAMP WHERE cart_id = $1 AND completed = 'started' AND lock_type = 'lock-stock' RETURNING id`
	var lockID int
	err = tx.QueryRow(query, cart_id).Scan(&lockID)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error updating cart_lock table: %w", err)
	}
	if lockID == 0 {
		tx.Rollback()
		return fmt.Errorf("no active cart_lock record found for cart_id %d", cart_id)
	}

	// Create a new cart_lock record for the payment phase
	query = `INSERT INTO cart_lock (cart_id, lock_type, completed, lock_timeout) VALUES ($1, 'lock-stock-pay', 'started', CURRENT_TIMESTAMP + INTERVAL '5 minutes')`
	_, err = tx.Exec(query, cart_id)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("error creating new cart_lock record for payment: %w", err)
	}

	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("error committing transaction: %w", err)
	}

	return nil
}
