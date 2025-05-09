package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) PaymentVerify(res http.ResponseWriter, req *http.Request) error {
	fmt.Println("Entered handlePostCheckoutLockItems")

	new_req := new(types.VerifyPayment)

	println("Customer Phone ", new_req.CustomerPhone)
	println("CartID ", new_req.CartID)
	println("MerchantTransactionID ", new_req.MerchantTransactionId)

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePostCheckoutLockItems()")
		return err
	}
	paymentVerified, err := s.store.PhonePeCheckStatus(new_req.CustomerPhone, new_req.CartID, new_req.MerchantTransactionId)
	if err != nil {
		print(err)
		return WriteJSON(res, http.StatusBadRequest, paymentVerified)
	}
	return WriteJSON(res, http.StatusOK, paymentVerified)
}
