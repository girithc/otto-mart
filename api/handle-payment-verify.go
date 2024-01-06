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

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in handlePostCheckoutLockItems()")
		return err
	}
	paymentVerified, err := s.store.PhonePeCheckStatus(new_req.CustomerPhone, new_req.CartID)
	if err != nil {
		return WriteJSON(res, http.StatusBadRequest, err)
	}
	return WriteJSON(res, http.StatusOK, paymentVerified)
}
