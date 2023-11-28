package store

import "fmt"

func (s *PostgresStore) Cancel_Checkout(cart_id int) error {
	cancel, exists := s.cancelFuncs[cart_id]
	if exists {
		delete(s.cancelFuncs, cart_id)
		cancel() // This cancels the monitoring goroutine and any internal goroutines it started
	} else {
		return fmt.Errorf("error: cart_id %d not found", cart_id)
	}

	return nil
}
