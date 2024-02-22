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

	// Check if the unique index already exists
	var exists bool
	checkIndexQuery := `SELECT EXISTS (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relname = 'vendor_name_phone_unique'
        AND n.nspname = 'public' -- or your specific schema if not public
    );`

	err = tx.QueryRow(checkIndexQuery).Scan(&exists)
	if err != nil {
		return fmt.Errorf("error checking for unique index: %w", err)
	}

	// If the unique index does not exist, create it
	if !exists {
		createIndexQuery := `CREATE UNIQUE INDEX vendor_name_phone_unique ON vendor (LOWER(name), phone);`
		_, err = tx.Exec(createIndexQuery)
		if err != nil {
			return fmt.Errorf("error creating unique index on vendor(name, phone): %w", err)
		}
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

func (s *PostgresStore) GetVendorList() ([]types.Vendor, error) {
	var vendors []types.Vendor
	query := `
    SELECT v.id, v.name, v.phone, v.email, v.delivery_frequency, v.delivery_day, v.mode_of_communication, v.notes, COALESCE(array_agg(b.name) FILTER (WHERE b.name IS NOT NULL), '{}') as brands
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
		var vendor types.Vendor
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

func (s *PostgresStore) AddVendor(vendor *types.AddVendor) (*types.Vendor, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}

	// Check for duplicate vendor
	var existingVendorID int
	checkVendorQuery := `SELECT id FROM vendor WHERE LOWER(name) = LOWER($1) AND phone = $2`
	err = tx.QueryRow(checkVendorQuery, vendor.Name, vendor.Phone).Scan(&existingVendorID)
	if err == nil {
		tx.Rollback() // Rollback the transaction as the vendor already exists
		return nil, fmt.Errorf("duplicate vendor exists with name: %s and phone: %s", vendor.Name, vendor.Phone)
	} else if err != sql.ErrNoRows {
		tx.Rollback() // Rollback the transaction due to an error
		return nil, fmt.Errorf("error checking for existing vendor: %w", err)
	}

	// Insert new vendor since no duplicate was found
	var newVendorID int
	vendorInsertQuery := `
        INSERT INTO vendor (name, phone, email, delivery_frequency, delivery_day, mode_of_communication, notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id;`
	err = tx.QueryRow(vendorInsertQuery, vendor.Name, vendor.Phone, vendor.Email, vendor.DeliveryFrequency, pq.Array(vendor.DeliveryDay), pq.Array(vendor.ModeOfCommunication), vendor.Notes).Scan(&newVendorID)
	if err != nil {
		tx.Rollback() // Rollback the transaction due to an error
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
		err = tx.QueryRow(brandQuery, brandNameLower).Scan(&brandID)
		if err != nil {
			if err == sql.ErrNoRows {
				// If the brand does not exist, insert it into the brand table
				insertBrandQuery := `INSERT INTO brand (name) VALUES ($1) RETURNING id`
				err = tx.QueryRow(insertBrandQuery, brandName).Scan(&brandID)
				if err != nil {
					tx.Rollback() // Rollback the transaction due to an error
					return nil, fmt.Errorf("error inserting new brand: %w", err)
				}
			} else {
				tx.Rollback() // Rollback the transaction due to an error
				return nil, fmt.Errorf("error querying for brand: %w", err)
			}
		}

		// After ensuring the brand exists and has an ID, add it to the brandNames slice
		brandNames = append(brandNames, brandName)

		// Insert the association between the vendor and the brand into the vendor_brand table
		_, err = tx.Exec(`INSERT INTO vendor_brand (vendor_id, brand_id) VALUES ($1, $2)`, newVendorID, brandID)
		if err != nil {
			tx.Rollback() // Rollback the transaction due to an error
			return nil, fmt.Errorf("error inserting into vendor_brand: %w", err)
		}
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		tx.Rollback() // Ensure rollback in case of failure to commit
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	// Create and return the new Vendor struct populated with the new vendor's information and associated brands
	newVendor := &types.Vendor{
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

func (s *PostgresStore) EditVendor(vendor types.Vendor) (*types.Vendor, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}

	// Update vendor details in the `vendor` table
	updateVendorQuery := `UPDATE vendor SET name = $1, phone = $2, email = $3, delivery_frequency = $4, delivery_day = $5, mode_of_communication = $6, notes = $7 WHERE id = $8`
	_, err = tx.Exec(updateVendorQuery, vendor.Name, vendor.Phone, vendor.Email, vendor.DeliveryFrequency, pq.Array(vendor.DeliveryDay), pq.Array(vendor.ModeOfCommunication), vendor.Notes, vendor.ID)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error updating vendor: %w", err)
	}

	// Fetch current brand associations for the vendor
	currentBrandsQuery := `SELECT brand_id FROM vendor_brand WHERE vendor_id = $1`
	rows, err := tx.Query(currentBrandsQuery, vendor.ID)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error fetching current brands: %w", err)
	}
	defer rows.Close()

	currentBrandIDs := make(map[int]struct{})
	for rows.Next() {
		var brandID int
		if err := rows.Scan(&brandID); err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("error scanning brand ID: %w", err)
		}
		currentBrandIDs[brandID] = struct{}{}
	}

	// Convert brand names to IDs
	desiredBrandIDs := make(map[int]struct{})
	for _, brandName := range vendor.Brands {
		var brandID int
		getBrandIDQuery := `SELECT id FROM brand WHERE LOWER(name) = LOWER($1)`
		err := tx.QueryRow(getBrandIDQuery, brandName).Scan(&brandID)
		if err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("error getting brand ID by name '%s': %w", brandName, err)
		}
		desiredBrandIDs[brandID] = struct{}{}
	}

	// Delete brands no longer associated with the vendor
	for brandID := range currentBrandIDs {
		if _, exists := desiredBrandIDs[brandID]; !exists {
			deleteBrandQuery := `DELETE FROM vendor_brand WHERE vendor_id = $1 AND brand_id = $2`
			_, err = tx.Exec(deleteBrandQuery, vendor.ID, brandID)
			if err != nil {
				tx.Rollback()
				return nil, fmt.Errorf("error deleting brand association: %w", err)
			}
		}
	}

	// Add new brand associations for the vendor
	for brandID := range desiredBrandIDs {
		if _, exists := currentBrandIDs[brandID]; !exists {
			insertBrandQuery := `INSERT INTO vendor_brand (vendor_id, brand_id) VALUES ($1, $2)`
			_, err = tx.Exec(insertBrandQuery, vendor.ID, brandID)
			if err != nil {
				tx.Rollback()
				return nil, fmt.Errorf("error inserting new brand association: %w", err)
			}
		}
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	return &vendor, nil
}
