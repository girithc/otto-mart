package store

import (
	"database/sql"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"strings"

	"cloud.google.com/go/storage"
	"github.com/girithc/pronto-go/types"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateStoreTable(tx *sql.Tx) error {
	// Create the store table if it doesn't exist
	createStoreTableQuery := `CREATE TABLE IF NOT EXISTS store (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        address VARCHAR(200) NOT NULL,
        latitude DECIMAL(10,8),  
        longitude DECIMAL(11,8), 
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by INT
    )`
	_, err := tx.Exec(createStoreTableQuery)
	if err != nil {
		return err // Return early if there's an error creating the table
	}

	// Create a unique index on the lowercase of the name column to enforce case-insensitive uniqueness
	createUniqueIndexQuery := `CREATE UNIQUE INDEX IF NOT EXISTS store_name_lower_idx ON store (LOWER(name))`
	_, err = tx.Exec(createUniqueIndexQuery)

	return err // Return any error that occurs when creating the index, or nil if successful
}

func (s *PostgresStore) Create_Store(st *types.Store) (*types.Store, error) {
	// Check if a store with the same name already exists
	checkQuery := `SELECT id, name, address, created_at, created_by FROM store WHERE name = $1`
	row := s.db.QueryRow(checkQuery, st.Name)
	existingStore := &types.Store{}
	err := row.Scan(&existingStore.ID, &existingStore.Name, &existingStore.Address, &existingStore.Created_At, &existingStore.Created_By)

	if err == nil {
		// Store with the same name exists, return the existing store
		return existingStore, nil
	} else if err != sql.ErrNoRows {
		// An error occurred other than "no rows in result set"
		return nil, err
	}

	// If no existing store is found, proceed to create a new one
	insertQuery := `INSERT INTO store (name, address, created_by) 
                    VALUES ($1, $2, $3) RETURNING id, name, address, created_at, created_by`
	rows, err := s.db.Query(insertQuery, st.Name, st.Address, st.Created_By)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	stores := []*types.Store{}
	for rows.Next() {
		store, err := scan_Into_Store(rows)
		if err != nil {
			return nil, err
		}
		stores = append(stores, store)
	}

	if len(stores) == 0 {
		return nil, errors.New("no store was created")
	}
	return stores[0], nil
}

func (s *PostgresStore) Get_Stores() ([]*types.Store, error) {
	rows, err := s.db.Query("select * from store")
	if err != nil {
		return nil, err
	}

	stores := []*types.Store{}
	for rows.Next() {
		store, err := scan_Into_Store(rows)
		if err != nil {
			return nil, err
		}
		stores = append(stores, store)
	}

	return stores, nil
}

func (s *PostgresStore) Get_Store_By_ID(id int) (*types.Store, error) {
	row, err := s.db.Query("select * from store where id = $1", id)
	if err != nil {
		return nil, err
	}

	for row.Next() {
		return scan_Into_Store(row)
	}

	return nil, fmt.Errorf("store with id = [%d] not found", id)
}

func (s *PostgresStore) Update_Store(st *types.Update_Store) (*types.Update_Store, error) {
	query := `update store
	set name = $1, address = $2
	where id = $3 
	returning name, address, id`

	rows, err := s.db.Query(
		query,
		st.Name,
		st.Address,
		st.ID,
	)
	if err != nil {
		return nil, err
	}

	stores := []*types.Update_Store{}

	for rows.Next() {
		store, err := scan_Into_Update_Store(rows)
		if err != nil {
			return nil, err
		}
		stores = append(stores, store)
	}

	return stores[0], nil
}

func (s *PostgresStore) Delete_Store(id int) error {
	_, err := s.db.Query("delete from store where id = $1", id)
	return err
}

func scan_Into_Store(rows *sql.Rows) (*types.Store, error) {
	store := new(types.Store)
	err := rows.Scan(
		&store.ID,
		&store.Name,
		&store.Address,
		&store.Latitude,  // Added to scan latitude
		&store.Longitude, // Added to scan longitude
		&store.Created_At,
		&store.Created_By,
	)

	return store, err
}

func scan_Into_Update_Store(rows *sql.Rows) (*types.Update_Store, error) {
	store := new(types.Update_Store)
	error := rows.Scan(
		&store.Name,
		&store.Address,
		&store.ID,
	)

	return store, error
}

// Helper function to get all table names
func getAllTableNames(db *sql.DB) ([]string, error) {
	query := "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';"
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tables []string
	for rows.Next() {
		var tablename string
		if err := rows.Scan(&tablename); err != nil {
			return nil, err
		}
		tables = append(tables, tablename)
	}

	return tables, nil
}

/*
	func (s *PostgresStore) ExportAllData() ([]string, error) {
		tables, err := getAllTableNames(s.db)
		if err != nil {
			return nil, err
		}

		var urls []string // Slice to store all file URLs

		for _, table := range tables {
			// Fetch all data from each table
			query := fmt.Sprintf("SELECT * FROM %s;", pq.QuoteIdentifier(table))
			rows, err := s.db.Query(query)
			if err != nil {
				return nil, err
			}

			// Create a CSV writer
			b := &strings.Builder{}
			csvWriter := csv.NewWriter(b)

			// Write CSV header
			columns, err := rows.Columns()
			if err != nil {
				rows.Close()
				return nil, err
			}
			csvWriter.Write(columns)

			// Write rows
			values := make([]interface{}, len(columns))
			valuePtrs := make([]interface{}, len(columns))
			for i := range values {
				valuePtrs[i] = &values[i]
			}

			for rows.Next() {
				rows.Scan(valuePtrs...)
				record := make([]string, len(columns))
				for i, col := range values {
					if col != nil {
						record[i] = fmt.Sprint(col)
					}
				}
				csvWriter.Write(record)
			}
			rows.Close()
			csvWriter.Flush()

			// Get a bucket handle
			bucketName := "seismic-ground-410711.appspot.com"
			bucket, err := s.firebaseStorage.Bucket(bucketName)
			if err != nil {
				return nil, fmt.Errorf("error getting bucket: %v", err)
			}

			objectName := "data/" + table + ".csv"
			obj := bucket.Object(objectName)

			// Upload the file
			w := obj.NewWriter(s.context)
			if _, err := io.Copy(w, strings.NewReader(b.String())); err != nil {
				w.Close()
				return nil, err
			}
			if err := w.Close(); err != nil {
				return nil, err
			}

			// Set file to public
			if err := obj.ACL().Set(s.context, storage.AllUsers, storage.RoleReader); err != nil {
				return nil, fmt.Errorf("error making file public: %v", err)
			}

			// Construct the public URL
			publicURL := fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, objectName)
			urls = append(urls, publicURL)
		}

		return urls, nil // Return all the public URLs
	}
*/
func (s *PostgresStore) ExportAllData() (string, error) {
	tables, err := getAllTableNames(s.db)
	if err != nil {
		return "", err
	}

	var fileDetails []struct {
		TableName string
		FileURL   string
	}

	for _, table := range tables {
		// Fetch all data from each table
		query := fmt.Sprintf("SELECT * FROM %s;", pq.QuoteIdentifier(table))
		rows, err := s.db.Query(query)
		if err != nil {
			return "", err
		}

		// Create a CSV writer
		b := &strings.Builder{}
		csvWriter := csv.NewWriter(b)

		// Write CSV header
		columns, err := rows.Columns()
		if err != nil {
			rows.Close()
			return "", err
		}
		csvWriter.Write(columns)

		// Write rows
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		for rows.Next() {
			rows.Scan(valuePtrs...)
			record := make([]string, len(columns))
			for i, col := range values {
				if col != nil {
					record[i] = fmt.Sprint(col)
				}
			}
			csvWriter.Write(record)
		}
		rows.Close()
		csvWriter.Flush()

		// Get a bucket handle
		bucketName := "seismic-ground-410711.appspot.com"
		bucket, err := s.firebaseStorage.Bucket(bucketName)
		if err != nil {
			return "", fmt.Errorf("error getting bucket: %v", err)
		}

		objectName := "data/" + table + ".csv"
		obj := bucket.Object(objectName)

		// Upload the file
		w := obj.NewWriter(s.context)
		if _, err := io.Copy(w, strings.NewReader(b.String())); err != nil {
			w.Close()
			return "", err
		}
		if err := w.Close(); err != nil {
			return "", err
		}

		// Set file to public
		if err := obj.ACL().Set(s.context, storage.AllUsers, storage.RoleReader); err != nil {
			return "", fmt.Errorf("error making file public: %v", err)
		}

		// Construct the public URL
		publicURL := fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, objectName)
		fileDetails = append(fileDetails, struct {
			TableName string
			FileURL   string
		}{TableName: table, FileURL: publicURL})
	}

	bucketName := "seismic-ground-410711.appspot.com"
	bucket, err := s.firebaseStorage.Bucket(bucketName)
	if err != nil {
		return "", fmt.Errorf("error getting bucket: %v", err)
	}

	// Create and upload summary CSV file
	summaryBuilder := &strings.Builder{}
	summaryWriter := csv.NewWriter(summaryBuilder)
	summaryWriter.Write([]string{"Table Name", "File URL"})
	for _, detail := range fileDetails {
		summaryWriter.Write([]string{detail.TableName, detail.FileURL})
	}
	summaryWriter.Flush()

	summaryObjectName := "data/summary.csv"
	summaryObj := bucket.Object(summaryObjectName)
	w := summaryObj.NewWriter(s.context)
	if _, err := io.Copy(w, strings.NewReader(summaryBuilder.String())); err != nil {
		w.Close()
		return "", err
	}
	if err := w.Close(); err != nil {
		return "", err
	}

	// Set summary file to public
	if err := summaryObj.ACL().Set(s.context, storage.AllUsers, storage.RoleReader); err != nil {
		return "", fmt.Errorf("error making summary file public: %v", err)
	}

	// Return the URL of the summary CSV file
	summaryURL := fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, summaryObjectName)
	return summaryURL, nil
}
