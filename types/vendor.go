package types

type AddVendor struct {
	Name                string   `json:"name"`
	Brands              []string `json:"brands"`
	Phone               string   `json:"phone"`
	Email               string   `json:"email"`
	DeliveryFrequency   string   `json:"delivery_frequency"`
	DeliveryDay         []string `json:"delivery_day"`
	ModeOfCommunication []string `json:"mode_of_communication"`
	Notes               string   `json:"notes"`
}
