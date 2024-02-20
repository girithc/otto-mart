package store

import (
	"database/sql"
	"fmt"
	"strings"

	"github.com/girithc/pronto-go/types"
	"github.com/lib/pq"
)

func (s *PostgresStore) CreateVendorTable(tx *sql.Tx) error {
	createVendorTableQuery := `
    CREATE TABLE IF NOT EXISTS vendor (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        phone VARCHAR(10) NOT NULL,
        email VARCHAR(100) NOT NULL,
        delivery_frequency VARCHAR(50) CHECK (delivery_frequency IN ('once', 'twice', 'thrice', 'all days')),
        delivery_day TEXT[] NOT NULL, 
        mode_of_communication TEXT[] NOT NULL,
        notes TEXT
    );`

	_, err := tx.Exec(createVendorTableQuery)
	if err != nil {
		return fmt.Errorf("error creating vendor table: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateVendorBrandTable(tx *sql.Tx) error {
	createVendorBrandTableQuery := `
	CREATE TABLE IF NOT EXISTS vendor_brand (
		vendor_id INTEGER REFERENCES vendor(id),
		brand_id INTEGER REFERENCES brand(id),
		PRIMARY KEY (vendor_id, brand_id)
	);`

	_, err := tx.Exec(createVendorBrandTableQuery)
	if err != nil {
		return fmt.Errorf("error creating brand table: %w", err)
	}

	return nil
}

func (s *PostgresStore) CreateBrandSchemeTable(tx *sql.Tx) error {
	createBrandSchemeTableQuery := `
    CREATE TABLE IF NOT EXISTS brand_scheme (
        id SERIAL PRIMARY KEY,
        brand_id INTEGER REFERENCES brand(id),
        vendor_id INTEGER REFERENCES vendor(id),
        discount DECIMAL(5,2) CHECK (discount >= 0 AND discount <= 100), 
        start_date DATE,
        end_date DATE,
        CONSTRAINT valid_dates CHECK (start_date <= end_date)
    );`

	_, err := tx.Exec(createBrandSchemeTableQuery)
	if err != nil {
		return fmt.Errorf("error creating brand_scheme table: %w", err)
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
	query := `
    SELECT v.id, v.name, v.phone, v.email, v.delivery_frequency, v.delivery_day, v.mode_of_communication, v.notes, array_agg(b.name) as brands
    FROM vendor v
    LEFT JOIN vendor_brand vb ON v.id = vb.vendor_id
    LEFT JOIN brand b ON vb.brand_id = b.id
    GROUP BY v.id`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error getting vendor list: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var vendor Vendor
		// Scan the brand names into the Brands field of the Vendor struct
		err := rows.Scan(&vendor.ID, &vendor.Name, &vendor.Phone, &vendor.Email, &vendor.DeliveryFrequency, pq.Array(&vendor.DeliveryDay), pq.Array(&vendor.ModeOfCommunication), &vendor.Notes, pq.Array(&vendor.Brands))
		if err != nil {
			return nil, fmt.Errorf("error scanning vendor list: %w", err)
		}

		vendors = append(vendors, vendor)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating vendor rows: %w", err)
	}

	return vendors, nil
}

func (s *PostgresStore) AddVendor(vendor *types.AddVendor) (*Vendor, error) {
	// Check for duplicate vendor
	var existingVendorID int
	checkVendorQuery := `SELECT id FROM vendor WHERE LOWER(name) = LOWER($1) AND phone = $2`
	err := s.db.QueryRow(checkVendorQuery, vendor.Name, vendor.Phone).Scan(&existingVendorID)
	if err == nil {
		return nil, fmt.Errorf("duplicate vendor exists with name: %s and phone: %s", vendor.Name, vendor.Phone)
	} else if err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing vendor: %w", err)
	}

	// Insert new vendor since no duplicate was found
	vendorInsertQuery := `
    INSERT INTO vendor (name, phone, email, delivery_frequency, delivery_day, mode_of_communication, notes)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id;`
	var newVendorID int
	err = s.db.QueryRow(vendorInsertQuery, vendor.Name, vendor.Phone, vendor.Email, vendor.DeliveryFrequency, pq.Array(vendor.DeliveryDay), pq.Array(vendor.ModeOfCommunication), vendor.Notes).Scan(&newVendorID)
	if err != nil {
		return nil, fmt.Errorf("error adding new vendor: %w", err)
	}

	// Initialize brandNames slice to store the names of the brands associated with the vendor
	var brandNames []string

	// Iterate through each brand provided in the vendor object
	for _, brandName := range vendor.Brands {
		var brandID int
		brandNameLower := strings.ToLower(brandName)

		// Check if the brand already exists
		brandQuery := `SELECT id FROM brand WHERE LOWER(name) = $1`
		err := s.db.QueryRow(brandQuery, brandNameLower).Scan(&brandID)
		if err != nil {
			if err == sql.ErrNoRows {
				// If the brand does not exist, insert it into the brand table
				insertBrandQuery := `INSERT INTO brand (name) VALUES ($1) RETURNING id`
				err = s.db.QueryRow(insertBrandQuery, brandName).Scan(&brandID)
				if err != nil {
					return nil, fmt.Errorf("error inserting new brand: %w", err)
				}
			} else {
				// If there was an error other than ErrNoRows, return the error
				return nil, fmt.Errorf("error querying for brand: %w", err)
			}
		}

		// After ensuring the brand exists and has an ID, add it to the brandNames slice
		brandNames = append(brandNames, brandName)

		// Insert the association between the vendor and the brand into the vendor_brand table
		_, err = s.db.Exec(`INSERT INTO vendor_brand (vendor_id, brand_id) VALUES ($1, $2)`, newVendorID, brandID)
		if err != nil {
			return nil, fmt.Errorf("error inserting into vendor_brand: %w", err)
		}
	}

	// Create and return the new Vendor struct populated with the new vendor's information and associated brands
	newVendor := &Vendor{
		ID:                  newVendorID,
		Name:                vendor.Name,
		Brands:              brandNames,
		Phone:               vendor.Phone,
		Email:               vendor.Email,
		DeliveryFrequency:   vendor.DeliveryFrequency,
		DeliveryDay:         vendor.DeliveryDay,
		ModeOfCommunication: vendor.ModeOfCommunication,
		Notes:               vendor.Notes,
	}

	return newVendor, nil
}

type Vendor struct {
	ID                  int      `json:"id"`
	Name                string   `json:"name"`
	Brands              []string `json:"brands"`
	Phone               string   `json:"phone"`
	Email               string   `json:"email"`
	DeliveryFrequency   string   `json:"delivery_frequency"`
	DeliveryDay         []string `json:"delivery_day"`
	ModeOfCommunication []string `json:"mode_of_communication"`
	Notes               string   `json:"notes"`
}
