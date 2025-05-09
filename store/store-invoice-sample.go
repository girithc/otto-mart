package store

/*

package store

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"strconv"
	"time"

	"cloud.google.com/go/storage"
	"github.com/jung-kurt/gofpdf"
)

type InvoiceItem struct {
	SrNo            int
	ItemDescription string
	Qty             int
	ProductRate     float64
	Disc            string
	TaxableAmt      float64
	CGST            string
	SGST            string
	CGSTAmt         float64
	SGSTAmt         float64
	Cess            string
	CessAmt         float64
	TotalAmt        float64
}

func (s *PostgresStore) genInvoice(orderID int) (string, []InvoiceItem, error) {
	query := `SELECT ci.quantity, i.name, ci.sold_price, if.mrp_price, t.sgst, t.cgst, t.cess, if.gst_on_mrp, if.cess_on_mrp, so.order_date, so.invoice_id, c.phone
              FROM cart_item ci
              JOIN item_store istore ON ci.item_id = istore.item_id
              JOIN item i ON istore.item_id = i.id
              JOIN sales_order so ON ci.cart_id = so.cart_id
              JOIN item_financial if ON i.id = if.item_id
              JOIN tax t ON if.tax_id = t.id
              JOIN customer c ON so.customer_id = c.id
              WHERE so.id = $1`
	rows, err := s.db.Query(query, orderID)
	if err != nil {
		return "", nil, fmt.Errorf("error fetching order items and customer details: %v", err)
	}
	defer rows.Close()

	// Open or create CSV file where all invoice items will be stored
	csvFile, err := os.OpenFile("invoice_items_march24.csv", os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0644)
	if err != nil {
		return "", nil, fmt.Errorf("error opening/creating CSV file: %v", err)
	}
	defer csvFile.Close()

	// Create a CSV writer
	writer := csv.NewWriter(csvFile)
	defer writer.Flush()

	var items []InvoiceItem
	var orderDate time.Time
	var invoiceID string
	var customerPhone string
	for rows.Next() {
		var qty int
		var name string
		var soldPrice, mrpPrice, cgstRate, sgstRate, cessRate, gstOnMrp, cessOnMrp float64
		if err := rows.Scan(&qty, &name, &soldPrice, &mrpPrice, &sgstRate, &cgstRate, &cessRate, &gstOnMrp, &cessOnMrp, &orderDate, &invoiceID, &customerPhone); err != nil {
			return "", nil, fmt.Errorf("error scanning order items and customer details: %v", err)
		}

		if customerPhone == "1234567890" {
			customerPhone = "9819982896"
		}

		// Convert basis points to percentage and calculate prices
		gstTotal := (cgstRate + sgstRate) / 10000.0
		cgstTotal := cgstRate / 10000.0
		sgstTotal := sgstRate / 10000.0
		cessFraction := cessRate / 10000.0

		rate := mrpPrice - gstOnMrp - cessOnMrp
		cgstAmount := (soldPrice / (1 + gstTotal + cessFraction)) * float64(qty) * cgstTotal
		sgstAmount := (soldPrice / (1 + gstTotal + cessFraction)) * float64(qty) * sgstTotal
		cessAmount := (soldPrice / (1 + gstTotal + cessFraction)) * float64(qty) * cessFraction

		taxableAmount := (soldPrice / (1 + gstTotal + cessFraction)) * float64(qty)
		discount := (rate * float64(qty)) - taxableAmount
		if discount <= 0 {
			discount = 0
		}

		items = append(items, InvoiceItem{
			ItemDescription: name,
			Qty:             qty,
			ProductRate:     rate,
			Disc:            fmt.Sprintf("%.2f", discount),
			TaxableAmt:      taxableAmount,
			CGST:            fmt.Sprintf("%.2f%%", (cgstRate/10000.0)*100),
			SGST:            fmt.Sprintf("%.2f%%", (sgstRate/10000.0)*100),
			CGSTAmt:         cgstAmount,
			SGSTAmt:         sgstAmount,
			Cess:            fmt.Sprintf("%.2f%%", cessFraction*100),
			CessAmt:         cessAmount,
			TotalAmt:        soldPrice * float64(qty),
		})
	}

	if len(items) == 0 {
		return "", nil, fmt.Errorf("no items found for order ID %d", orderID)
	}

	// Create PDF
	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 10, "Invoice")
	pdf.Ln(12)

	pdf.SetFont("Arial", "", 10)
	pdf.CellFormat(190, 10, "Dur Durdarshi Retail Private Limited", "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 10, "208, Ground Floor, Shree Ashtavinayak CHS Limited, Old DN Nagar Road, Andheri West, Mumbai 400053", "", 1, "L", false, 0, "")

	pdf.Ln(10)

	pdf.CellFormat(190, 10, "Invoice ID: "+invoiceID, "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 10, "Order Date: "+orderDate.Format("02-01-2006")+"     Customer Phone: "+customerPhone, "", 1, "L", false, 0, "")
	pdf.Ln(10)

	pdf.SetFont("Arial", "", 8)

	// Check if the file is new to write the header
	if fileInfo, _ := csvFile.Stat(); fileInfo.Size() == 0 {
		// Writing header to the CSV file
		header := []string{"Invoice Id", "Item Description", "Qty", "Rate", "Disc.", "Taxable Amt.", "CGST %", "SGST %", "CGST Amt.", "SGST Amt.", "Cess %", "Cess Amt.", "Total", "Order Date", "Customer Phone"}
		if err := writer.Write(header); err != nil {
			return "", nil, fmt.Errorf("error writing header to CSV file: %v", err)
		}
	}

	headers := []string{"Sr No", "Item Description", "Qty", "Rate", "Disc.", "Taxable Amt.", "CGST %", "SGST %", "CGST Amt.", "SGST Amt.", "Cess %", "Cess Amt.", "Total"}
	headerWidths := []float64{10, 30, 8, 15, 10, 18, 13, 13, 15, 15, 12, 15, 20}
	for i, header := range headers {
		pdf.CellFormat(headerWidths[i], 12, header, "1", 0, "C", false, 0, "")
	}
	pdf.Ln(-1)
	y := 95.0 // Starting Y position for items

	for i, item := range items {
		maxHeight := 6.0
		wrappedText := pdf.SplitLines([]byte(item.ItemDescription), headerWidths[1])
		if len(wrappedText) > 1 {
			maxHeight = float64(len(wrappedText)) * 6.0
		}

		pdf.CellFormat(headerWidths[0], maxHeight, strconv.Itoa(i+1), "1", 0, "C", false, 0, "")
		pdf.MultiCell(headerWidths[1], 6, item.ItemDescription, "1", "L", false)
		pdf.SetXY(50, pdf.GetY()-maxHeight) // Reset X to right of description cell, and Y to the top of the cell
		pdf.CellFormat(headerWidths[2], maxHeight, strconv.Itoa(item.Qty), "1", 0, "C", false, 0, "")
		pdf.CellFormat(headerWidths[3], maxHeight, fmt.Sprintf("%.2f", item.ProductRate), "1", 0, "R", false, 0, "")
		pdf.CellFormat(headerWidths[4], maxHeight, item.Disc, "1", 0, "R", false, 0, "")
		pdf.CellFormat(headerWidths[5], maxHeight, fmt.Sprintf("%.2f", item.TaxableAmt), "1", 0, "R", false, 0, "")
		pdf.CellFormat(headerWidths[6], maxHeight, item.CGST, "1", 0, "C", false, 0, "")
		pdf.CellFormat(headerWidths[7], maxHeight, item.SGST, "1", 0, "C", false, 0, "")
		pdf.CellFormat(headerWidths[8], maxHeight, fmt.Sprintf("%.2f", item.CGSTAmt), "1", 0, "R", false, 0, "")
		pdf.CellFormat(headerWidths[9], maxHeight, fmt.Sprintf("%.2f", item.SGSTAmt), "1", 0, "R", false, 0, "")
		pdf.CellFormat(headerWidths[10], maxHeight, item.Cess, "1", 0, "C", false, 0, "")
		pdf.CellFormat(headerWidths[11], maxHeight, fmt.Sprintf("%.2f", item.CessAmt), "1", 0, "R", false, 0, "")
		pdf.CellFormat(headerWidths[12], maxHeight, fmt.Sprintf("%.2f", item.TotalAmt), "1", 0, "R", false, 0, "")
		pdf.Ln(maxHeight)
		y += maxHeight // Move to the next line for the next item
		// Move to next line

		record := []string{
			invoiceID,
			item.ItemDescription,
			fmt.Sprintf("%d", item.Qty),
			fmt.Sprintf("%.2f", item.ProductRate),
			item.Disc,
			fmt.Sprintf("%.2f%%", item.TaxableAmt),
			item.CGST,
			item.SGST,
			fmt.Sprintf("%.2f", item.CGSTAmt),
			fmt.Sprintf("%.2f", item.SGSTAmt),
			item.Cess,
			fmt.Sprintf("%.2f", item.CessAmt),
			fmt.Sprintf("%.2f", item.TotalAmt),
			orderDate.Format("02-01-2006"),
			customerPhone,
		}
		if err := writer.Write(record); err != nil {
			return "", nil, fmt.Errorf("error writing item to CSV file: %v", err)
		}
	}

	// Total price calculation
	totalPrice := 0.0
	for _, item := range items {
		totalPrice += item.TotalAmt
	}

	pdf.SetXY(10, y) // Adjust X to align with the first column, Y is the next line after the last item
	pdf.CellFormat(185, 10, "Total Invoice Amount: "+strconv.FormatFloat(totalPrice, 'f', 2, 64), "1", 0, "R", false, 0, "")

	filename := fmt.Sprintf("invoice_%d_order.pdf", orderID)
	err = pdf.OutputFileAndClose(filename)
	if err != nil {
		return "", nil, fmt.Errorf("failed to create PDF file: %v", err)
	}

	return filename, items, nil
}

func (s *PostgresStore) GenInvoice() (string, error) {
	// Retrieve all order IDs that need invoices generated
	orderIDs, err := s.getAllOrderIDs()
	if err != nil {
		return "", fmt.Errorf("error retrieving order IDs: %v", err)
	}

	csvFilename := "invoice_items.csv"
	// Ensure the CSV file is initially empty/created
	file, err := os.Create(csvFilename)
	if err != nil {
		return "", fmt.Errorf("error creating CSV file: %v", err)
	}
	file.Close()

	for _, orderID := range orderIDs {
		filename, items, err := s.genInvoice(orderID)
		if err != nil {
			fmt.Printf("error generating invoice for order ID %d: %v\n", orderID, err)
			continue
		}

		bucketName := "seismic-ground-410711.appspot.com"
		bucket, err := s.firebaseStorage.Bucket(bucketName)
		if err != nil {
			fmt.Printf("error getting default bucket for order ID %d: %v\n", orderID, err)
			continue
		}

		file, err := os.Open(filename)
		if err != nil {
			fmt.Printf("error opening file %s for order ID %d: %v\n", filename, orderID, err)
			continue
		}
		defer file.Close()

		objectName := "invoices_pdf/" + time.Now().Format("2006-01-02_15-04-05") + "_" + filename
		object := bucket.Object(objectName)

		wc := object.NewWriter(s.context)
		if _, err = io.Copy(wc, file); err != nil {
			fmt.Printf("error writing to Firebase Storage for order ID %d: %v\n", orderID, err)
			continue
		}
		if err := wc.Close(); err != nil {
			fmt.Printf("error closing writer for order ID %d: %v\n", orderID, err)
			continue
		}

		if err := object.ACL().Set(s.context, storage.AllUsers, storage.RoleReader); err != nil {
			fmt.Printf("error making file public for order ID %d: %v\n", orderID, err)
			continue
		}

		publicURL := fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, objectName)

		// Update the sales order table
		sqlStatement := `UPDATE sales_order SET invoice_url = $1 WHERE id = $2`
		if _, err = s.db.Exec(sqlStatement, publicURL, orderID); err != nil {
			fmt.Printf("error updating sales order table for order ID %d: %v\n", orderID, err)
			continue
		}

		fmt.Printf("Invoice uploaded successfully for order ID %d. Public URL: %s\n", orderID, publicURL)
		_ = items // This is where you would handle invoice items, if necessary
	}

	bucketName := "seismic-ground-410711.appspot.com"
	bucket, err := s.firebaseStorage.Bucket(bucketName)
	if err != nil {
		fmt.Printf("error getting default bucket \n")

	}

	// After processing all invoices, upload the CSV file
	csvFile, err := os.Open(csvFilename)
	if err != nil {
		return "", fmt.Errorf("error opening CSV file: %v", err)
	}
	defer csvFile.Close()

	csvObjectName := "invoices_csv/" + "item_invoice_2024_03.csv"
	csvObject := bucket.Object(csvObjectName)
	wcCsv := csvObject.NewWriter(s.context)
	if _, err = io.Copy(wcCsv, csvFile); err != nil {
		return "", fmt.Errorf("error writing CSV to Firebase Storage: %v", err)
	}
	if err := wcCsv.Close(); err != nil {
		return "", fmt.Errorf("error closing CSV writer: %v", err)
	}

	if err := csvObject.ACL().Set(s.context, storage.AllUsers, storage.RoleReader); err != nil {
		return "", fmt.Errorf("error making CSV file public: %v", err)
	}

	csvPublicURL := fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, csvObjectName)
	fmt.Printf("CSV file uploaded successfully. Public URL: %s\n", csvPublicURL)

	return csvPublicURL, nil
}

func (s *PostgresStore) getAllOrderIDs() ([]int, error) {
	// The SQL query now includes a WHERE clause to filter orders by date and an ORDER BY clause to sort them
	query := `
        SELECT id FROM sales_order
        WHERE order_date <= '2024-03-31'
        ORDER BY order_date ASC
    `
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("error querying order IDs: %v", err)
	}
	defer rows.Close()

	var orderIDs []int
	for rows.Next() {
		var id int
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("error scanning order ID: %v", err)
		}
		orderIDs = append(orderIDs, id)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error during rows iteration: %v", err)
	}

	return orderIDs, nil
}


*/
