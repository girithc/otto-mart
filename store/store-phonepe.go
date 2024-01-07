package store

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

type PhonePeCheckStatus struct {
	Status string `json:"status"`
	Done   bool   `json:"done"`
	Amount int    `json:"amount"`
}

func (s *PostgresStore) PhonePeCheckStatus(customerPhone string, cartID int) (PhonePeCheckStatus, error) {
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

	var response PhonePeCheckStatus

	transaction, err := s.GetTransactionByCartId(cartID)
	if err != nil {
		response.Done = false
		response.Status = "transaction not found"
		response.Amount = 0
		return response, fmt.Errorf("error fetching transaction: %w", err)
	}

	// Check if S2S callback has been received
	if transaction.ResponseCode == "SUCCESS" {
		response.Done = true
		response.Status = "SUCCESS"
		response.Amount = transaction.Amount
		return response, nil
	} else if transaction.ResponseCode == "ZU" {
		// LOG POTENTIAL REFUND
		response.Done = false
		response.Status = "FAILED"
		response.Amount = transaction.Amount
		return response, nil
	}

	// If S2S callback not received, call Check Status API
	success, err := s.CallCheckStatusAPI(transaction.MerchantId, transaction.MerchantTransactionId, transaction.Amount)
	if err != nil {
		// LOG POTENTIAL REFUND
		response.Status = "FAILED"
		response.Done = false
		response.Amount = 0
		return response, err
	}

	if success.Done {
	}

	return success, nil
}

func (s *PostgresStore) GetTransactionByCartId(cart_id int) (*types.Transaction, error) {
	var transaction types.Transaction

	// Updated query to fetch the latest transaction based on transaction_date
	query := `
        SELECT merchant_transaction_id, merchant_id, response_code, status, amount 
        FROM transaction 
        WHERE cart_id = $1 AND status != 'pending'
        ORDER BY transaction_date DESC 
        LIMIT 1`

	err := s.db.QueryRow(query, cart_id).Scan(&transaction.MerchantTransactionId, &transaction.MerchantId, &transaction.ResponseCode, &transaction.Status, &transaction.Amount)
	if err != nil {
		return nil, err
	}

	return &transaction, nil
}

func (s *PostgresStore) CallCheckStatusAPI(merchantId, merchantTransactionId string, amout int) (PhonePeCheckStatus, error) {
	// Construct the URL
	fmt.Println("Entered CallCheckStatusAPI")
	url := fmt.Sprintf("https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/%s/%s", merchantId, merchantTransactionId)

	// Create the request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Println("Error creating request:", err)

		var response PhonePeCheckStatus
		response.Done = false
		response.Status = "REQUEST ERROR"
		return response, nil
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-VERIFY", GenerateXVerify(merchantId, merchantTransactionId))
	req.Header.Set("X-MERCHANT-ID", merchantId)

	// Execute the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error executing request:", err)
		var response PhonePeCheckStatus
		response.Done = false
		response.Status = "REQUEST_ERROR_2"
		return response, nil
	}
	defer resp.Body.Close()

	// Read and print the response body
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		var response PhonePeCheckStatus
		response.Done = false
		response.Status = "REQUEST_ERROR_RESPONSE"
		return response, nil
	}
	bodyString := string(bodyBytes)
	fmt.Println("Response Body:", bodyString)

	// Parse the response
	var response struct {
		Success bool               `json:"success"`
		Code    string             `json:"code"`
		Message string             `json:"message"`
		Data    *types.PaymentData `json:"data"`
	}
	err = json.Unmarshal(bodyBytes, &response)
	if err != nil {
		fmt.Println("Error decoding response:", err)
		var respCheckStatus PhonePeCheckStatus
		respCheckStatus.Done = false
		respCheckStatus.Status = "REQUEST_ERROR_RESPONSE"
		return respCheckStatus, nil
	}

	// Check if the response was successful
	if response.Success {
		if response.Data != nil && response.Data.State == "COMPLETED" {
			fmt.Println("Transaction completed successfully")

			// update transaction

			var respCheckStatus PhonePeCheckStatus
			respCheckStatus.Done = true
			respCheckStatus.Status = "PAYMENT_SUCCESS"
			respCheckStatus.Amount = response.Data.Amount
			return respCheckStatus, nil
		}
		var respCheckStatus PhonePeCheckStatus
		respCheckStatus.Done = false
		respCheckStatus.Status = "PAYMENT_PENDING"
		respCheckStatus.Amount = response.Data.Amount
		// update transaction

		return respCheckStatus, nil
	} else {
		// Handle failure scenarios
		errMsg := fmt.Sprintf("API call failed: %s - %s", response.Code, response.Message)
		fmt.Println(errMsg)

		// update transaction

		var respCheckStatus PhonePeCheckStatus
		respCheckStatus.Done = false
		respCheckStatus.Status = response.Code
		respCheckStatus.Amount = response.Data.Amount
		// You can customize the error based on the response code if needed
		return respCheckStatus, errors.New(errMsg)
	}
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

func (s *PostgresStore) PhonePePaymentComplete(cart_id int) error {
	return nil
}

func (s *PostgresStore) PhonePePaymentInit(cart_id int) (*types.PhonePeResponse, error) {
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
	query = `INSERT INTO cart_lock (cart_id, lock_type, completed, lock_timeout) VALUES ($1, 'lock-stock-pay', 'started', CURRENT_TIMESTAMP + INTERVAL '9 minutes')`
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

	paymentData := paymentResponse.Data

	type PaymentType struct {
		Type string `json:"type"`
	}

	var paymentType PaymentType
	err = json.Unmarshal(paymentData.PaymentInstrument, &paymentType)
	if err != nil {
		fmt.Printf("Error unmarshalling instrument type: %v\n", err)
		return nil, err
	}
	instrumentType := paymentType.Type
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

	// Extract cart_id from the transaction record
	var cartID string
	queryCartID := `SELECT cart_id FROM transaction WHERE merchant_transaction_id = $1`
	err = s.db.QueryRow(queryCartID, paymentResponse.Data.MerchantTransactionId).Scan(&cartID)
	if err != nil {
		fmt.Printf("Error fetching cart ID: %v\n", err)
		return nil, err
	}

	// Update cart lock record with lock type having pay-verify and completed having started
	updateCartLockQuery := `
    UPDATE cart_lock
    SET completed = 'success'
    WHERE cart_id = $1 AND lock_type = 'pay-verify',`
	_, err = s.db.Exec(updateCartLockQuery, cartID)
	if err != nil {
		fmt.Printf("Error updating cart lock record: %v\n", err)
		return nil, err
	}

	// Insert a new cart_lock record with lock-type paid, completed as success
	insertCartLockQuery := `
    INSERT INTO cart_lock (cart_id, lock_type, completed)
    VALUES ($1, 'paid', 'success')`
	_, err = s.db.Exec(insertCartLockQuery, cartID)
	if err != nil {
		fmt.Printf("Error inserting new cart lock record: %v\n", err)
		return nil, err
	}

	// Prepare and execute the SQL update query
	updateQuery := `
    UPDATE transaction
    SET status = $1, 
        response_code = $2,
        payment_details = $3,
		payment_method = $4,
		merchant_id = $5,
		payment_gateway_name = $6,
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
