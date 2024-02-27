package store

import (
	"database/sql"
	"fmt"
)

func (s *PostgresStore) CreateItemFinancialTable(tx *sql.Tx) error {
	createItemFinancialTableQuery := `
    CREATE TABLE IF NOT EXISTS item_financial (
        item_id INT PRIMARY KEY REFERENCES item(id) ON DELETE CASCADE,
        buy_price DECIMAL(10, 2),  
        gst_on_buy DECIMAL(10, 2),
        buy_price_without_gst DECIMAL(10, 2) GENERATED ALWAYS AS (buy_price - gst_on_buy) STORED,
        mrp_price DECIMAL(10, 2),
        gst_on_mrp DECIMAL(10, 2),
        mrp_price_without_gst DECIMAL(10, 2) GENERATED ALWAYS AS (mrp_price - gst_on_mrp) STORED,
        margin_net DECIMAL(5, 2) GENERATED ALWAYS AS (CASE WHEN (mrp_price - gst_on_mrp) = 0 THEN NULL ELSE (1 - (buy_price - gst_on_buy) / (mrp_price - gst_on_mrp)) * 100 END) STORED,
        margin DECIMAL(5, 2),
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
	ItemID             int             `json:"item_id"`
	ItemName           string          `json:"item_name"`
	UnitOfQuantity     string          `json:"unit_of_quantity"`
	Quantity           int             `json:"quantity"`
	BuyPrice           sql.NullFloat64 `json:"buy_price,omitempty"`
	GSTOnBuy           sql.NullFloat64 `json:"gst_on_buy,omitempty"`
	BuyPriceWithoutGST sql.NullFloat64 `json:"buy_price_without_gst,omitempty"`
	MRPPrice           sql.NullFloat64 `json:"mrp_price,omitempty"`
	GSTOnMRP           sql.NullFloat64 `json:"gst_on_mrp,omitempty"`
	MRPPriceWithoutGST sql.NullFloat64 `json:"mrp_price_without_gst,omitempty"`
	MarginNet          sql.NullFloat64 `json:"margin_net,omitempty"`
	Margin             sql.NullFloat64 `json:"margin,omitempty"`
	TaxID              sql.NullInt32   `json:"tax_id,omitempty"`            // Adjusted for potential NULL values
	CurrentSchemeID    sql.NullInt32   `json:"current_scheme_id,omitempty"` // Adjusted for potential NULL values
}

func (s *PostgresStore) ManagerGetItemFinancialByItemId(itemID int) (*ItemFinancialDetails, error) {
	var details ItemFinancialDetails

	query := `
    SELECT i.id, i.name, i.unit_of_quantity, i.quantity, 
           if.buy_price, if.gst_on_buy, if.buy_price_without_gst, 
           if.mrp_price, if.gst_on_mrp, if.mrp_price_without_gst, 
           if.margin_net, if.margin, if.tax_id, if.current_scheme_id
    FROM item i
    LEFT JOIN item_financial if ON i.id = if.item_id
    WHERE i.id = $1
    `

	err := s.db.QueryRow(query, itemID).Scan(
		&details.ItemID, &details.ItemName, &details.UnitOfQuantity, &details.Quantity,
		&details.BuyPrice, &details.GSTOnBuy, &details.BuyPriceWithoutGST,
		&details.MRPPrice, &details.GSTOnMRP, &details.MRPPriceWithoutGST,
		&details.MarginNet, &details.Margin, &details.TaxID, &details.CurrentSchemeID,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no item found with ID %d", itemID)
		}
		return nil, fmt.Errorf("error retrieving item financial details: %w", err)
	}

	return &details, nil
}

func (s *PostgresStore) ManagerEditItemFinancialByItemId(itemFinance ItemFinance) (*ItemFinancialDetails, error) {
	var existingID int
	checkExistenceQuery := `SELECT item_id FROM item_financial WHERE item_id = $1`
	err := s.db.QueryRow(checkExistenceQuery, itemFinance.ItemID).Scan(&existingID)

	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing item financial record: %w", err)
	}

	if err == sql.ErrNoRows {
		// Record does not exist, insert a new record
		insertQuery := `
		INSERT INTO item_financial (item_id, buy_price, mrp_price, gst_on_buy, margin)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING item_id
		`
		err = s.db.QueryRow(insertQuery, itemFinance.ItemID, itemFinance.BuyPrice, itemFinance.MRPPrice, itemFinance.GST, itemFinance.Margin).Scan(&existingID)
		if err != nil {
			return nil, fmt.Errorf("error inserting new item financial record: %w", err)
		}
	} else {
		// Record exists, update the existing record
		updateQuery := `
		UPDATE item_financial
		SET buy_price = $2, mrp_price = $3, gst_on_buy = $4, margin = $5
		WHERE item_id = $1
		`
		_, err = s.db.Exec(updateQuery, itemFinance.ItemID, itemFinance.BuyPrice, itemFinance.MRPPrice, itemFinance.GST, itemFinance.Margin)
		if err != nil {
			return nil, fmt.Errorf("error updating existing item financial record: %w", err)
		}
	}

	// Retrieve the updated/inserted item financial details
	return s.ManagerGetItemFinancialByItemId(itemFinance.ItemID)
}

type ItemFinance struct {
	ItemID   int     `json:"item_id"`
	BuyPrice float64 `json:"buy_price"`
	MRPPrice float64 `json:"mrp_price"`
	GST      float64 `json:"gst"`
	Margin   float64 `json:"margin"`
}
