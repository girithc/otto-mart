package store

import (
	"database/sql"
)

func (s *PostgresStore) CreateShelfTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS Shelf (
        id SERIAL PRIMARY KEY,
        store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
        horizontal INT NOT NULL,  
		barcode VARCHAR(15) UNIQUE,
        vertical VARCHAR(1) NOT NULL,  
        UNIQUE(store_id, horizontal, vertical)
    );`

	_, err := tx.Exec(query)
	return err
}

// CreateShelf inserts a new shelf into the database and returns its details.
func (s *PostgresStore) CreateShelf(storeID, horizontal int, barcode, vertical string) (*Shelf, error) {
	// SQL query to insert a new shelf and return its details.
	shelfInsertQuery := `
    INSERT INTO Shelf (store_id, horizontal, barcode, vertical) 
    VALUES ($1, $2, $3, $4) 
    RETURNING id, store_id, horizontal, barcode, vertical`

	// The shelf object to hold the returned data.
	newShelf := &Shelf{}

	// Execute the query and scan the returned row into the newShelf object.
	err := s.db.QueryRow(shelfInsertQuery, storeID, horizontal, barcode, vertical).Scan(
		&newShelf.ID, &newShelf.StoreID, &newShelf.Horizontal, &newShelf.Barcode, &newShelf.Vertical)
	// Handle potential errors during the query execution.
	if err != nil {
		return nil, err
	}

	// Return the newly created shelf details.
	return newShelf, nil
}

// Shelf represents the structure of a shelf in the database.
type Shelf struct {
	ID         int    `json:"id"`
	StoreID    int    `json:"store_id"`
	Horizontal int    `json:"horizontal"`
	Barcode    string `json:"barcode"`
	Vertical   string `json:"vertical"`
}
