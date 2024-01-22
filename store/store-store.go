package store

import (
	"database/sql"
	"errors"
	"fmt"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateStoreTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateStoreTable")

	query := `create table if not exists store (
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) UNIQUE NOT NULL,
		address VARCHAR(200) NOT NULL,
		latitude DECIMAL(10,8),  
        longitude DECIMAL(11,8), 
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_by INT	
	)`

	_, err := tx.Exec(query)

	// fmt.Println("Exiting CreateStoreTable")

	return err
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
