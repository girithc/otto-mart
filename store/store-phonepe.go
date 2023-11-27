package store

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) PhonePePaymentInit() (*types.PhonePeResponse, error) {
	// Hardcoded values for PhonePeInit
	phonepe := &types.PhonePeInit{
		MerchantId:            "PGTESTPAYUAT",
		MerchantTransactionId: "MT7850590068188104",
		MerchantUserId:        "MUID123",
		Amount:                10000,
		RedirectUrl:           "https://youtube.com/redirect-url",
		RedirectMode:          "REDIRECT",
		CallbackUrl:           "https://webhook.site/callback-url",
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

	return &response, nil
}

func (s *PostgresStore) CalculateCartTotal(cartId int) (int64, error) {
	// SQL query to calculate the total amount
	query := `
	SELECT SUM(i.store_price * c.quantity) as total
	FROM cart_item c
	JOIN item_store i ON c.item_id = i.id
	WHERE c.cart_id = $1
	`

	var total int64
	err := s.db.QueryRow(query, cartId).Scan(&total)
	if err != nil {
		return 0, err
	}

	return total, nil
}
