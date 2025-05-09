package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) CreateItemFinancialTable(tx *sql.Tx) error {
	createItemFinancialTableQuery := `
    CREATE TABLE IF NOT EXISTS item_financial (
        item_id INT PRIMARY KEY REFERENCES item(id) ON DELETE CASCADE,
        buy_price DECIMAL(10, 2),  
        mrp_price DECIMAL(10, 2),
        gst_on_buy DECIMAL(10, 2),
        gst_on_mrp DECIMAL(10, 2),
        cess_on_buy DECIMAL(10, 2),
        cess_on_mrp DECIMAL(10, 2),
        margin_net DECIMAL(10, 2) GENERATED ALWAYS AS (CASE WHEN (mrp_price - gst_on_mrp - cess_on_mrp) = 0 THEN NULL ELSE (1 - (buy_price - gst_on_buy - cess_on_buy) / (mrp_price - gst_on_mrp - cess_on_mrp)) * 100 END) STORED,
        margin DECIMAL(10, 2),
        tax_id INT REFERENCES tax(id) ON DELETE SET NULL,  
        current_scheme_id INT REFERENCES item_scheme(id) ON DELETE SET NULL
    );`

	_, err := tx.Exec(createItemFinancialTableQuery)
	if err != nil {
		return fmt.Errorf("error creating item_financial table: %w", err)
	}

	return nil
}

type ItemFinancialDetails struct {
	ItemID          int             `json:"item_id"`
	ItemName        string          `json:"item_name"`
	UnitOfQuantity  string          `json:"unit_of_quantity"`
	Quantity        int             `json:"quantity"`
	BuyPrice        sql.NullFloat64 `json:"buy_price,omitempty"`
	MRPPrice        sql.NullFloat64 `json:"mrp_price,omitempty"`
	GSTRate         sql.NullFloat64 `json:"gst_rate,omitempty"` // GST rate as a percentage
	Cess            sql.NullFloat64 `json:"cess,omitempty"`     // Cess rate as a percentage
	GSTOnBuy        sql.NullFloat64 `json:"gst_on_buy,omitempty"`
	GSTOnMRP        sql.NullFloat64 `json:"gst_on_mrp,omitempty"`
	CessOnBuy       sql.NullFloat64 `json:"cess_on_buy,omitempty"`
	CessOnMRP       sql.NullFloat64 `json:"cess_on_mrp,omitempty"`
	Margin          sql.NullFloat64 `json:"margin,omitempty"`
	TaxID           sql.NullInt32   `json:"tax_id,omitempty"`            // Adjusted for potential NULL values
	CurrentSchemeID sql.NullInt32   `json:"current_scheme_id,omitempty"` // Adjusted for potential NULL values
	// New fields added from item_scheme table
	Discount        sql.NullFloat64 `json:"discount,omitempty"`         // Discount percentage
	MinimumQuantity sql.NullInt32   `json:"minimum_quantity,omitempty"` // Minimum quantity for discount to apply
	StartDate       sql.NullString  `json:"start_date,omitempty"`       // Start date of the discount scheme
	EndDate         sql.NullString  `json:"end_date,omitempty"`         // End date of the discount scheme
}

func (s *PostgresStore) ManagerGetItemFinancialByItemId(itemID int) (*ItemFinancialDetails, error) {
	var details ItemFinancialDetails

	// Extended the query to include item_scheme fields
	query := `
    SELECT i.id, i.name, i.unit_of_quantity, i.quantity,
           (if.buy_price - if.gst_on_buy - if.cess_on_buy) AS adjusted_buy_price,
           if.mrp_price, t.gst as gst_rate, t.cess as cess_rate,
           if.gst_on_buy, if.cess_on_buy, if.gst_on_mrp, if.cess_on_mrp,
           if.margin, if.tax_id, if.current_scheme_id,
           istore.discount, istore.minimum_quantity, istore.start_date, istore.end_date  -- New fields from item_scheme
    FROM item i
    LEFT JOIN item_financial if ON i.id = if.item_id
    LEFT JOIN tax t ON if.tax_id = t.id
    LEFT JOIN item_scheme istore ON i.id = istore.item_id  -- Join with item_scheme table
    WHERE i.id = $1
    `

	// Add fields to scan into, handling potential NULL values appropriately
	err := s.db.QueryRow(query, itemID).Scan(
		&details.ItemID, &details.ItemName, &details.UnitOfQuantity, &details.Quantity,
		&details.BuyPrice, // This will now hold the adjusted buy price
		&details.MRPPrice, &details.GSTRate, &details.Cess,
		&details.GSTOnBuy, &details.CessOnBuy, &details.GSTOnMRP, &details.CessOnMRP,
		&details.Margin, &details.TaxID, &details.CurrentSchemeID,
		// New fields
		&details.Discount, &details.MinimumQuantity, &details.StartDate, &details.EndDate,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no item found with ID %d", itemID)
		}
		return nil, fmt.Errorf("error retrieving item financial details: %w", err)
	}

	return &details, nil
}

func (s *PostgresStore) ManagerEditItemFinancialByItemId(itemFinance types.ItemFinance) (*ItemFinancialDetails, error) {
	var existingID int
	checkExistenceQuery := `SELECT item_id FROM item_financial WHERE item_id = $1`
	err := s.db.QueryRow(checkExistenceQuery, itemFinance.ItemID).Scan(&existingID)

	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing item financial record: %w", err)
	}

	// Calculate GST and Cess rates
	var gstRate, cessRate float64

	if itemFinance.GST > 28 {
		gstRate = 0.28                          // 28% as a decimal
		cessRate = (itemFinance.GST - 28) / 100 // Excess over 28% as a decimal
	} else {
		gstRate = itemFinance.GST / 100 // Convert to decimal
		cessRate = 0
	}

	buyPriceIncTax := itemFinance.BuyPrice * (1 + (gstRate + cessRate))
	//mrpPriceIncTax := itemFinance.MRPPrice

	buyPriceExclTax := itemFinance.BuyPrice
	mrpPriceExclTax := itemFinance.MRPPrice / (1 + (gstRate + cessRate))

	// Calculate exclusive Buy Price and MRP
	//buyPriceExclTax := itemFinance.BuyPrice / (1 + gstRate + cessRate)
	//mrpExclTax := itemFinance.MRPPrice / (1 + gstRate + cessRate)

	// Calculate GST and Cess on exclusive prices
	gstOnBuyPrice := buyPriceExclTax * gstRate
	cessOnBuyPrice := buyPriceExclTax * cessRate

	gstOnMRP := mrpPriceExclTax * gstRate
	cessOnMRP := mrpPriceExclTax * cessRate

	gstRate = gstRate * 100   // Convert to percentage
	cessRate = cessRate * 100 // Convert to percentage

	var taxID int
	// Query to fetch the matching tax_id from the tax table
	getTaxIDQuery := `SELECT id FROM tax WHERE gst = $1 AND cess = $2`
	err = s.db.QueryRow(getTaxIDQuery, gstRate*100, cessRate*100).Scan(&taxID) // Assuming tax table stores rates as percentages
	if err != nil {
		return nil, fmt.Errorf("error fetching tax ID from tax table: %w", err)
	}

	if existingID == 0 {
		// Record does not exist, insert a new record
		insertQuery := `
            INSERT INTO item_financial (item_id, buy_price, mrp_price, gst_on_buy, cess_on_buy, gst_on_mrp, cess_on_mrp, margin, tax_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING item_id
        `
		err = s.db.QueryRow(insertQuery, itemFinance.ItemID, buyPriceIncTax, itemFinance.MRPPrice, gstOnBuyPrice, cessOnBuyPrice, gstOnMRP, cessOnMRP, itemFinance.Margin, taxID).Scan(&existingID)
		if err != nil {
			return nil, fmt.Errorf("error updating existing item financial record with GST: %.2f%%, Cess: %.2f%%: %w", gstRate*100, cessRate*100, err)
		}

	} else {
		// Record exists, update the existing record
		updateQuery := `
            UPDATE item_financial
            SET buy_price = $2, mrp_price = $3, gst_on_buy = $4, cess_on_buy = $5, gst_on_mrp = $6, cess_on_mrp = $7, margin = $8, tax_id = $9
            WHERE item_id = $1
        `
		_, err = s.db.Exec(updateQuery, itemFinance.ItemID, buyPriceIncTax, itemFinance.MRPPrice, gstOnBuyPrice, cessOnBuyPrice, gstOnMRP, cessOnMRP, itemFinance.Margin, taxID)
		if err != nil {
			return nil, fmt.Errorf("error updating existing item financial record:  %w", err)
		}
	}

	var schemeID int
	// Check if a record exists in item_scheme for the given item_id
	checkSchemeExistenceQuery := `SELECT id FROM item_scheme WHERE item_id = $1`
	err = s.db.QueryRow(checkSchemeExistenceQuery, itemFinance.ItemID).Scan(&schemeID)

	if err != nil && err != sql.ErrNoRows {
		// Handle unexpected errors
		return nil, fmt.Errorf("error checking for existing item scheme record: %w", err)
	}

	if err == sql.ErrNoRows {
		// No existing record, insert a new one
		insertSchemeQuery := `
            INSERT INTO item_scheme (item_id, discount, minimum_quantity, start_date, end_date)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id
        `
		err = s.db.QueryRow(insertSchemeQuery, itemFinance.ItemID, itemFinance.Discount, itemFinance.MinimumQuantity, itemFinance.StartDate, itemFinance.EndDate).Scan(&schemeID)
		if err != nil {
			return nil, fmt.Errorf("error inserting new item scheme record: %w", err)
		}
	} else {
		// Existing record, update it
		updateSchemeQuery := `
            UPDATE item_scheme
            SET discount = $2, minimum_quantity = $3, start_date = $4, end_date = $5
            WHERE item_id = $1
        `
		_, err = s.db.Exec(updateSchemeQuery, itemFinance.ItemID, itemFinance.Discount, itemFinance.MinimumQuantity, itemFinance.StartDate, itemFinance.EndDate)
		if err != nil {
			return nil, fmt.Errorf("error updating existing item scheme record: %w", err)
		}
	}

	// Retrieve the updated item financial details along with item scheme details
	return s.ManagerGetItemFinancialByItemId(itemFinance.ItemID)
}

type ItemFinance struct {
	ItemID   int     `json:"item_id"`
	BuyPrice float64 `json:"buy_price"`
	MRPPrice float64 `json:"mrp_price"`
	GST      float64 `json:"gst"`
	Margin   float64 `json:"margin"`
}
