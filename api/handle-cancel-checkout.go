package api

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/girithc/pronto-go/types"
)

func (s *Server) HandleCancelCheckoutCart(res http.ResponseWriter, req *http.Request) error {
	new_req := new(types.CancelCheckout)
	print("Entered Create Category")

	if err := json.NewDecoder(req.Body).Decode(new_req); err != nil {
		fmt.Println("Error in Decoding req.body in HandleCancelCheckoutCart()")
		return err
	}

	err := s.store.Cancel_Checkout(new_req.CartID, new_req.Sign)
	if err != nil {
		return err
	}

	return WriteJSON(res, http.StatusOK, nil)
}
