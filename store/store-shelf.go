package store

import (
	"database/sql"
	"fmt"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) CreateShelfTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS Shelf (
        id SERIAL PRIMARY KEY,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        horizontal INT NOT NULL,  
		item_id INT REFERENCES Item(id) ON DELETE CASCADE,
        vertical VARCHAR(1) NOT NULL,  
        UNIQUE(store_id, horizontal, vertical)
    );`

	_, err := tx.Exec(query)
	return err
}

func (s *PostgresStore) CreateDeliveryShelfTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS delivery_shelf (
        id SERIAL PRIMARY KEY,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        location INT NOT NULL,
        order_id INT REFERENCES sales_order(id) ON DELETE CASCADE,
        UNIQUE(store_id, location)
    );`

	_, err := tx.Exec(query)
	return err
}

// CreateShelf inserts a new shelf into the database and returns its details.
func (s *PostgresStore) CreateShelf(storeID, horizontal int, vertical string) (*Shelf, error) {
	// SQL query to insert a new shelf and return its details.
	shelfInsertQuery := `
    INSERT INTO Shelf (store_id, horizontal, vertical) 
    VALUES ($1, $2, $3, $4) 
    RETURNING id, store_id, horizontal, vertical`

	// The shelf object to hold the returned data.
	newShelf := &Shelf{}

	// Execute the query and scan the returned row into the newShelf object.
	err := s.db.QueryRow(shelfInsertQuery, storeID, horizontal, vertical).Scan(
		&newShelf.ID, &newShelf.StoreID, &newShelf.Horizontal, &newShelf.Vertical)
	// Handle potential errors during the query execution.
	if err != nil {
		return nil, err
	}

	// Return the newly created shelf details.
	return newShelf, nil
}

// GetShelf retrieves all shelves associated with a given store ID from the database.
func (s *PostgresStore) GetShelf(storeID int) ([]Shelf, error) {
	// SQL query to select shelves based on storeID.
	shelfSelectQuery := `SELECT id, store_id, horizontal, item_id, vertical FROM Shelf WHERE store_id = $1`

	// Execute the query with storeID as the parameter.
	rows, err := s.db.Query(shelfSelectQuery, storeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Slice to hold the shelves.
	var shelves []Shelf

	// Iterate through the rows.
	for rows.Next() {
		var shelf Shelf
		// Scan each row into a Shelf struct.
		if err := rows.Scan(&shelf.ID, &shelf.StoreID, &shelf.Horizontal, &shelf.ItemID, &shelf.Vertical); err != nil {
			return nil, err
		}
		// Append the Shelf struct to the slice.
		shelves = append(shelves, shelf)
	}

	// Check for any error encountered during iteration.
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Return the slice of shelves.
	return shelves, nil
}

func (s *PostgresStore) ManagerInitShelf(storeID int) (bool, error) {
	verticals := []string{"A", "B", "C", "D", "E", "F", "G", "H"}
	success := true

	for _, vertical := range verticals {
		for horizontal := 1; horizontal <= 130; horizontal++ {
			query := `
			INSERT INTO Shelf (store_id, horizontal, vertical)
			VALUES ($1, $2, $3)
			ON CONFLICT (store_id, horizontal, vertical) DO NOTHING;
			`
			_, err := s.db.Exec(query, storeID, horizontal, vertical)
			if err != nil {
				success = false
				// Log the error (consider using a logging library)
				fmt.Printf("Failed to insert shelf: %v\n", err)
				// Decide if you want to continue or return on the first error
				// For this example, we'll continue trying to insert other shelves
			}
		}
	}

	success = true

	for location := 1; location <= 28; location++ {
		query := `
			INSERT INTO Delivery_Shelf (store_id, location)
			VALUES ($1, $2)
			ON CONFLICT (store_id, location) DO NOTHING;
			`
		_, err := s.db.Exec(query, storeID, location)
		if err != nil {
			success = false
			fmt.Printf("Failed to insert shelf: %v\n", err)
		}
	}

	return success, nil
}

// ShelfAssignmentResponse is used to return details and status about the shelf assignment operation.
type ShelfAssignmentResponse struct {
	Horizontal int    `json:"horizontal"`
	Vertical   string `json:"vertical"`
	ItemName   string `json:"itemName,omitempty"` // omitempty will not include itemName in JSON if it's empty
	Message    string `json:"message"`
}

// Assuming PostgresStore structure and other necessary imports and setups are already done

func (s *PostgresStore) ManagerAssignItemToShelf(req types.AssignItemShelf) (*ShelfAssignmentResponse, error) {
	var currentItemID int
	var newItemName string
	shelfID := fmt.Sprintf("%s%d", req.Vertical, req.Horizontal)

	// Retrieve the name of the item to be assigned
	getItemNameQuery := `
	SELECT name FROM Item WHERE barcode = $1;
	`
	err := s.db.QueryRow(getItemNameQuery, req.ItemBarcode).Scan(&newItemName)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("item with barcode '%s' does not exist", req.ItemBarcode)
		}
		return nil, fmt.Errorf("error retrieving item name: %v", err)
	}

	// Check if the shelf already has an item assigned and if it does, validate the stock and locked quantity
	checkQuery := `
	SELECT i.id
	FROM Shelf s
	LEFT JOIN item i ON s.item_id = i.id
	LEFT JOIN item_store istore ON i.id = istore.item_id
	WHERE s.store_id = $1 AND s.horizontal = $2 AND s.vertical = $3
	AND (istore.stock_quantity > 0 OR istore.locked_quantity > 0);
	`
	err = s.db.QueryRow(checkQuery, req.StoreID, req.Horizontal, req.Vertical).Scan(&currentItemID)
	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking current shelf item: %v", err)
	}
	if currentItemID != 0 {
		message := fmt.Sprintf("Shelf %s already has an item with stock or locked quantity", shelfID)
		return &ShelfAssignmentResponse{Horizontal: req.Horizontal, Vertical: req.Vertical, Message: message}, fmt.Errorf(message)
	}

	// Check if the item is already assigned to another shelf and has locked quantity greater than 0
	otherShelfCheckQuery := `
	SELECT COUNT(*)
	FROM Shelf s
	JOIN item i ON s.item_id = i.id
	JOIN item_store istore ON i.id = istore.item_id
	WHERE i.barcode = $1 AND s.store_id = $2 AND (s.horizontal != $3 OR s.vertical != $4) AND istore.locked_quantity > 0;
	`
	var count int
	err = s.db.QueryRow(otherShelfCheckQuery, req.ItemBarcode, req.StoreID, req.Horizontal, req.Vertical).Scan(&count)
	if err != nil {
		return nil, fmt.Errorf("error checking other shelves for the item: %v", err)
	}
	if count > 0 {
		message := fmt.Sprintf("Item '%s' is already assigned to another shelf with locked quantity", newItemName)
		return &ShelfAssignmentResponse{Horizontal: req.Horizontal, Vertical: req.Vertical, Message: message}, fmt.Errorf(message)
	}
	// Assign the item to the shelf
	updateQuery := `
	UPDATE Shelf
	SET item_id = (SELECT id FROM Item WHERE barcode = $1)
	WHERE store_id = $2 AND horizontal = $3 AND vertical = $4;
	`
	_, err = s.db.Exec(updateQuery, req.ItemBarcode, req.StoreID, req.Horizontal, req.Vertical)
	if err != nil {
		return nil, fmt.Errorf("error updating shelf: %v", err)
	}

	// Return the ShelfAssignmentResponse struct with a success message and the item name
	response := &ShelfAssignmentResponse{
		Horizontal: req.Horizontal,
		Vertical:   req.Vertical,
		ItemName:   newItemName,
		Message:    fmt.Sprintf("Success: Item '%s' assigned to shelf %s", newItemName, shelfID),
	}
	return response, nil
}

// Shelf represents the structure of a shelf in the database.
type Shelf struct {
	ID         int    `json:"id"`
	StoreID    int    `json:"store_id"`
	Horizontal int    `json:"horizontal"`
	Vertical   string `json:"vertical"`
	ItemID     int    `json:"item_id"`
}
