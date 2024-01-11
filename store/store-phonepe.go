package store

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"

	"github.com/girithc/pronto-go/types"
)

type PhonePeCheckStatus struct {
	Status        string `json:"status"`
	Done          bool   `json:"done"`
	Amount        int    `json:"amount"`
	PaymentMethod string `json:"payment_method"`
}

func (s *PostgresStore) PhonePeCheckStatus(customerPhone string, cartID int, merchantTransactionID string) (PhonePeCheckStatus, error) {
	println("PhonePeCheckStatus started")

	var response PhonePeCheckStatus

	println("Fetching transaction")
	transaction, err := s.GetTransactionByCartId(cartID, merchantTransactionID)
	if err != nil {
		println("Error fetching transaction:", err)
		response.Done = false
		response.Status = "transaction not found"
		response.Amount = 0
		return response, fmt.Errorf("error fetching transaction: %w", err)
	}

	println("Checking transaction response code")
	if transaction.ResponseCode == "SUCCESS" {
		println("Transaction SUCCESS")
		response.Done = true
		response.Status = "SUCCESS"
		response.Amount = transaction.Amount
		response.PaymentMethod = transaction.PaymentMethod
		return response, nil

	} else if transaction.ResponseCode == "ZU" {
		println("Transaction ZU - potential refund")
		response.Done = false
		response.Status = "FAILED"
		response.Amount = transaction.Amount
		return response, nil
	}

	println("Calling Check Status API")
	trx, err := s.CallCheckStatusAPI(transaction.MerchantId, transaction.MerchantTransactionId, transaction.Amount)
	if err != nil {
		println("Error calling Check Status API:", err)
		response.Status = "FAILED"
		response.Done = false
		response.Amount = 0
		return response, err
	}

	println("Checking trx response code")
	if trx.ResponseCode == "SUCCESS" {
		println("trx SUCCESS - beginning database transaction")
		tx, err := s.db.Begin()
		if err != nil {
			println("Error starting database transaction:", err)
			response.Done = false
			response.Status = "FAILED"
			response.Amount = 0
			return response, fmt.Errorf("error starting transaction: %w", err)
		}

		println("Setting transaction details")
		var payDetails TransactionDetails
		payDetails.Status = trx.Status
		payDetails.MerchantID = trx.MerchantID
		payDetails.MerchantTransactionID = trx.MerchantTransactionID
		payDetails.PaymentDetails = trx.PaymentDetails
		payDetails.ResponseCode = trx.ResponseCode
		payDetails.PaymentGatewayName = trx.PaymentGatewayName
		payDetails.PaymentMethod = trx.PaymentMethod
		payDetails.TransactionID = trx.TransactionID

		println("Completing transaction")
		_, err = s.CompleteTransaction(tx, payDetails)
		if err != nil {
			println("Error completing transaction:", err)
			tx.Rollback()
			return response, err
		}

		println("Creating order")
		_, err = s.CreateOrder(tx, cartID, transaction.PaymentMethod, transaction.MerchantTransactionId)
		if err != nil {
			println("Error creating order:", err)
			tx.Rollback() // Rollback the transaction on error
			return response, err
		}

		println("Committing transaction")
		err = tx.Commit()
		if err != nil {
			println("Error committing transaction:", err)
			response.Done = false
			response.Status = "FAILED"
			response.Amount = 0
			return response, fmt.Errorf("error committing transaction: %w", err)
		}

		println("Transaction completed successfully")
		response.Done = true
		response.Status = "SUCCESS"
		response.Amount = transaction.Amount
		response.PaymentMethod = trx.PaymentMethod
		return response, nil
	} else {
		println("trx response code not SUCCESS")
		response.Done = false
		response.Status = "FAILED"
		response.Amount = transaction.Amount
		response.PaymentMethod = trx.PaymentMethod
		return response, nil
	}
}

func (s *PostgresStore) GetTransactionByCartId(cart_id int, merchantTransactionID string) (*types.Transaction, error) {
	var transaction types.Transaction

	// Updated query to fetch the latest transaction based on transaction_date
	query := `
        SELECT merchant_transaction_id, merchant_id, response_code, status, amount, payment_method, 
		payment_details, payment_gateway_name 
        FROM transaction 
        WHERE cart_id = $1 AND status = 'COMPLETED' AND merchant_transaction_id = $2
        ORDER BY transaction_date DESC 
        LIMIT 1`

	err := s.db.QueryRow(query, cart_id, merchantTransactionID).Scan(&transaction.MerchantTransactionId, &transaction.MerchantId, &transaction.ResponseCode, &transaction.Status, &transaction.Amount,
		&transaction.PaymentMethod, &transaction.PaymentDetails, &transaction.PaymentGatewayName)
	if err != nil {
		return nil, err
	}

	return &transaction, nil
}

func (s *PostgresStore) CallCheckStatusAPI(merchantId, merchantTransactionId string, amout int) (TransactionDetails, error) {
	// Construct the URL
	fmt.Println("Entered CallCheckStatusAPI")
	url := fmt.Sprintf("https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/%s/%s", merchantId, merchantTransactionId)

	// Create the request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Println("Error creating request:", err)

		var response TransactionDetails
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
		var response TransactionDetails
		response.Status = "REQUEST_ERROR_2"
		return response, nil
	}
	defer resp.Body.Close()

	// Read and print the response body
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		var response TransactionDetails
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
		var respCheckStatus TransactionDetails
		respCheckStatus.Status = "REQUEST_ERROR_RESPONSE"
		return respCheckStatus, nil
	}

	// Check if the response was successful
	if response.Success {
		if response.Data != nil && response.Data.State == "COMPLETED" {
			fmt.Println("Transaction completed successfully")

			// update transaction

			var payDetails TransactionDetails
			payDetails.Status = response.Code
			payDetails.MerchantID = response.Data.MerchantId
			payDetails.MerchantTransactionID = response.Data.MerchantTransactionId
			payDetails.PaymentDetails = response.Data.PaymentInstrument
			payDetails.ResponseCode = response.Data.ResponseCode
			payDetails.PaymentGatewayName = "PhonePe"
			payDetails.PaymentMethod = "credit"
			return payDetails, nil
		}
		var payDetails TransactionDetails
		payDetails.Status = response.Code
		payDetails.MerchantID = "ERROR"
		payDetails.MerchantTransactionID = "ERROR"
		payDetails.PaymentDetails = "ERROR"
		payDetails.ResponseCode = "ERROR"
		payDetails.PaymentGatewayName = "PhonePe"
		payDetails.PaymentMethod = "credit"
		return payDetails, nil
	} else {
		// Handle failure scenarios
		errMsg := fmt.Sprintf("API call failed: %s - %s", response.Code, response.Message)
		fmt.Println(errMsg)

		// update transaction

		var payDetails TransactionDetails
		payDetails.Status = response.Code
		payDetails.MerchantID = response.Data.MerchantId
		payDetails.MerchantTransactionID = response.Data.MerchantTransactionId
		payDetails.PaymentDetails = response.Data.PaymentInstrument
		payDetails.ResponseCode = response.Data.ResponseCode
		payDetails.PaymentGatewayName = "PhonePe"
		payDetails.PaymentMethod = "credit"
		return payDetails, nil
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

func (s *PostgresStore) PhonePePaymentInit(cart_id int, sign string, merchantTransactionID string) (*types.PhonePeResponsePlus, error) {
	phonepe := &types.PhonePeInit{
		MerchantId:        "PGTESTPAYUAT",
		RedirectUrl:       "https://youtube.com/redirect-url",
		RedirectMode:      "REDIRECT",
		CallbackUrl:       fmt.Sprintf("https://pronto-go-3ogvsx3vlq-el.a.run.app/phonepe-callback?cart_id=%d&sign=%s", cart_id, url.QueryEscape(sign)),
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
		if err == sql.ErrNoRows {
			// No rows found, return a custom error message
			var respFinal types.PhonePeResponsePlus
			respFinal.Success = false
			respFinal.Message = "timeout error"
			return &respFinal, nil
		}
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
	if response.Success {
		// reset timer
		sign, updated, err := s.InitiatePayment(cart_id, sign, merchantTransactionID)
		if err != nil {
			return nil, err
		}

		var respFinal types.PhonePeResponsePlus
		if !updated {
			respFinal.Success = false
			if sign == "no-stock" {
				respFinal.Message = "timeout error"
				return &respFinal, nil
			}
			return &respFinal, nil
		} else {
			respFinal.Code = response.Code
			respFinal.Data = response.Data
			respFinal.Message = response.Message
			respFinal.Sign = sign
			respFinal.Success = response.Success
			respFinal.MerchantTransactionId = phonepe.MerchantTransactionId
			return &respFinal, nil
		}

	} else {
		var respFinal types.PhonePeResponsePlus
		respFinal.Success = false
		respFinal.Message = "payment error"
		return &respFinal, nil
	}
}

func (s *PostgresStore) InitiatePayment(cart_id int, sign string, merchantTransactionID string) (string, bool, error) {
	// Begin a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return "", false, fmt.Errorf("error starting transaction: %w", err)
	}

	// Check for an existing cart_lock record and update it
	query := `UPDATE cart_lock SET completed = 'success', last_updated = CURRENT_TIMESTAMP WHERE cart_id = $1 AND completed = 'started' AND lock_type = 'lock-stock' AND sign = $2 RETURNING id`
	var lockID int
	err = tx.QueryRow(query, cart_id, sign).Scan(&lockID)
	if err != nil {
		tx.Rollback()
		return "", false, fmt.Errorf("error updating cart_lock table: %w", err)
	}
	if lockID == 0 {
		err = tx.Commit()
		if err != nil {
			return "", false, fmt.Errorf("error committing transaction: %w", err)
		}
		return "no-stock", false, nil
	}

	// Create a new cart_lock record for the payment phase
	query = `INSERT INTO cart_lock (cart_id, lock_type, completed, lock_timeout) 
         VALUES ($1, 'lock-stock-pay', 'started', CURRENT_TIMESTAMP + INTERVAL '9 minutes') 
         RETURNING sign`

	var signValue string
	err = tx.QueryRow(query, cart_id).Scan(&signValue)
	if err != nil {
		tx.Rollback()
		return "", false, fmt.Errorf("error creating new cart_lock record for payment and retrieving sign: %w", err)
	}

	_ = s.CreateCloudTask(cart_id, "lock-stock-pay", signValue, merchantTransactionID)
	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		return "", false, fmt.Errorf("error committing transaction: %w", err)
	}

	return signValue, true, nil
}

func (s *PostgresStore) PhonePePaymentCallback(cartID int, sign string, response string) (*types.PaymentCallbackResult, error) {
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
	var modeOfPayment string

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
		modeOfPayment = "upi"
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &upi)
		if err != nil {
			fmt.Printf("Error unmarshalling UPI payment instrument: %v\n", err)
			return nil, err
		}
		paymentInstrument = upi
	case "CARD": // Assuming "CARD"  is the type for credit/debit cards
		var card types.CardPaymentInstrument
		modeOfPayment = card.CardType
		if modeOfPayment == "CREDIT_CARD" {
			modeOfPayment = "credit card"
		} else {
			modeOfPayment = "debit card"
		}
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &card)
		if err != nil {
			fmt.Printf("Error unmarshalling CARD payment instrument: %v\n", err)
			return nil, err
		}
		paymentInstrument = card
	case "NETBANKING": // Assuming "NETBANKING" is the type for net banking
		var netBanking types.NetBankingPaymentInstrument
		modeOfPayment = "net banking"
		err = json.Unmarshal(paymentResponse.Data.PaymentInstrument, &netBanking)
		if err != nil {
			fmt.Printf("Error unmarshalling NETBANKING payment instrument: %v\n", err)
			return nil, err
		}
		paymentInstrument = netBanking
	default:
		return nil, fmt.Errorf("unknown payment instrument type: %s", instrumentType)
	}

	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		fmt.Printf("Error starting transaction: %v\n", err)
		return nil, err
	}

	// Update cart lock record with lock type having pay-verify and completed having started
	updateCartLockQuery := `
    UPDATE cart_lock
    SET completed = 'success'
    WHERE cart_id = $1 AND lock_type = 'pay-verify' AND sign = $2`

	if _, err = tx.Exec(updateCartLockQuery, cartID, sign); err != nil {
		tx.Rollback()
		fmt.Printf("Error updating cart lock record: %v\n", err)
		return nil, err
	}

	// Insert a new cart_lock record with lock-type paid, completed as success
	insertCartLockQuery := `
    INSERT INTO cart_lock (cart_id, lock_type, completed)
    VALUES ($1, 'paid', 'success')`

	if _, err = tx.Exec(insertCartLockQuery, cartID); err != nil {
		tx.Rollback()
		fmt.Printf("Error inserting new cart lock record: %v\n", err)
		return nil, err
	}

	var payDetails TransactionDetails
	payDetails.Status = paymentResponse.Data.State
	payDetails.MerchantID = paymentResponse.Data.MerchantId
	payDetails.MerchantTransactionID = paymentResponse.Data.MerchantTransactionId
	payDetails.PaymentDetails = paymentInstrument
	payDetails.ResponseCode = paymentResponse.Data.ResponseCode
	payDetails.PaymentGatewayName = "PhonePe"
	payDetails.PaymentMethod = modeOfPayment
	payDetails.TransactionID = paymentResponse.Data.TransactionId

	_, err = s.CompleteTransaction(tx, payDetails)
	if err != nil {
		return nil, err
	}

	/*
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

			if _, err = tx.Exec(updateQuery, paymentResponse.Data.State, paymentResponse.Data.ResponseCode,
				paymentInstrument, instrumentType, paymentResponse.Data.MerchantId, "PhonePe", paymentResponse.Data.MerchantTransactionId); err != nil {
				tx.Rollback()
				fmt.Printf("Error updating transaction record: %v\n", err)
				return nil, err
			}
	*/
	_, err = s.CreateOrder(tx, cartID, payDetails.PaymentMethod, payDetails.MerchantTransactionID)
	if err != nil {
		tx.Rollback() // Rollback the transaction on error
		return nil, err
	}

	// Commit the transaction
	if err = tx.Commit(); err != nil {
		fmt.Printf("Error committing transaction: %v\n", err)
		return nil, err
	}

	// Create the result struct
	result := &types.PaymentCallbackResult{
		PaymentResponse:   paymentResponse,
		PaymentInstrument: paymentInstrument,
	}

	return result, nil
}
