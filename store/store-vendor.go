package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreateVendorTable(tx *sql.Tx) error {
	createVendorTableQuery := `
    CREATE TABLE IF NOT EXISTS vendor (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        brand_id INTEGER REFERENCES brand(id), -- Assuming there's a 'brand' table with an 'id' column
        phone VARCHAR(10) NOT NULL,
        email VARCHAR(100) NOT NULL,
        delivery_frequency VARCHAR(50) CHECK (delivery_frequency IN ('once', 'twice', 'thrice', 'All days')),
        delivery_day VARCHAR(255), -- Storing CSV format for multiple days selection
        mode_of_communication VARCHAR(50) CHECK (mode_of_communication IN ('whatsapp', 'email')),
        notes TEXT
    );`

	_, err := tx.Exec(createVendorTableQuery)
	if err != nil {
		return fmt.Errorf("error creating vendor table: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateItemVendorTable(tx *sql.Tx) error {
	createItemVendorTableQuery := `
    CREATE TABLE IF NOT EXISTS item_vendor (
        id SERIAL PRIMARY KEY,
        item_id INT NOT NULL,
        vendor_id INT NOT NULL,
        purchase_price DECIMAL(10, 2) NOT NULL,
        purchase_date DATE NOT NULL,
        store_id INT NOT NULL,
        quantity INT NOT NULL CHECK (quantity > 0),
        invoice_number VARCHAR(50),
        is_paid BOOLEAN NOT NULL DEFAULT FALSE,
        paid_date DATE NULL,
        credit_days INT NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by INT,
        FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE,
        FOREIGN KEY (vendor_id) REFERENCES vendor(id) ON DELETE CASCADE,
        FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE CASCADE
    );`

	_, err := tx.Exec(createItemVendorTableQuery)
	if err != nil {
		return fmt.Errorf("error creating item_vendor table: %w", err)
	}

	return nil
}

func (s *PostgresStore) GetVendorList() ([]Vendor, error) {
	var vendors []Vendor
	query := "SELECT * FROM vendor"
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error getting vendor list: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var vendor Vendor
		err := rows.Scan(&vendor.ID, &vendor.Name, &vendor.BrandID, &vendor.Phone, &vendor.Email, &vendor.DeliveryFrequency, &vendor.DeliveryDay, &vendor.ModeOfCommunication, &vendor.Notes)
		if err != nil {
			return nil, fmt.Errorf("error scanning vendor list: %w", err)
		}
		vendors = append(vendors, vendor)
	}

	return vendors, nil
}

type Vendor struct {
	ID                  int    `json:"id"`
	Name                string `json:"name"`
	BrandID             int    `json:"brand_id"`
	Phone               string `json:"phone"`
	Email               string `json:"email"`
	DeliveryFrequency   string `json:"delivery_frequency"`
	DeliveryDay         string `json:"delivery_day"`
	ModeOfCommunication string `json:"mode_of_communication"`
	Notes               string `json:"notes"`
}
