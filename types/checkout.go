package types

type Checkout struct {
	Cart_Id int  `json:"cart_id"`
	Payment bool `json:"payment"`
}

type Checkout_Cart_Item struct {
	Item_Id  int `json:"item_id"`
	Quantity int `json:"quantity"`
}

type Checkout_Lock_Items struct {
	Cart_Id               int    `json:"cart_id"`
	Cash                  bool   `json:"cash"`
	Sign                  string `json:"sign"`
	MerchantTransactionId string `json:"merchant_transaction_id"`
}

type Checkout_Init struct {
	Cart_Id int `json:"cart_id"`
}

type CancelCheckout struct {
	CartID                int    `json:"cart_id"`
	Sign                  string `json:"sign"`
	LockType              string `json:"lock_type"`
	MerchantTransactionId string `json:"merchantTransactionId"`
}
