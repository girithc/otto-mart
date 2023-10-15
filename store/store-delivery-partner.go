package store

import (
	"database/sql"

	"github.com/girithc/pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateDeliveryPartnerTable(tx *sql.Tx) error {
	// fmt.Println("Entered CreateItemTable")

	query := `create table if not exists delivery_partner(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		fcm_token TEXT NOT NULL,
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		phone VARCHAR(10) NOT NULL, 
		address TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := tx.Exec(query)

	// fmt.Println("Exiting CreateItemTable")

	return err
}

// 1. Create a function to insert a new delivery partner
func (s *PostgresStore) Create_Delivery_Partner(dp *types.Create_Delivery_Partner) (*types.Delivery_Partner, error) {
	query := `insert into delivery_partner
	(name, phone, address, fcm_token, store_id) 
	values ($1, $2, $3, $4, $5) returning id, name, fcm_token, store_id, phone, address, created_at
	`

	rows, err := s.db.Query(
		query,
		"",
		dp.Phone,
		"",
		"",
		1,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.Delivery_Partner{}
	for rows.Next() {
		partner, err := scan_Into_Delivery_Partner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}
	return partners[0], nil
}

func (s *PostgresStore) Update_FCM_Token_Delivery_Partner(phone int, fcm_token string) (*types.Delivery_Partner, error) {
	// Start a transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback() // This will rollback any changes in case of error or if the commit fails

	// Reset existing rows with the same fcm_token to 0
	resetStatement := `
        UPDATE delivery_partner
        SET fcm_token = '0'
        WHERE fcm_token = $1
    `
	_, err = tx.Exec(resetStatement, fcm_token)
	if err != nil {
		return nil, err
	}

	// Update the fcm_token for the matching phone
	sqlStatement := `
        UPDATE delivery_partner
        SET fcm_token = $1
        WHERE phone = $2
        RETURNING id, name, fcm_token, store_id, phone, address, created_at
    `

	// Execute the SQL statement
	row := tx.QueryRow(sqlStatement, fcm_token, phone)

	partner := &types.Delivery_Partner{}
	err = row.Scan(&partner.ID, &partner.Name, &partner.FCM_Token, &partner.Store_ID, &partner.Phone, &partner.Address, &partner.Created_At)
	if err != nil {
		return nil, err
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return partner, nil
}

// 2. Create a function to retrieve all delivery partners
func (s *PostgresStore) Get_All_Delivery_Partners() ([]*types.Delivery_Partner, error) {
	query := `select * from delivery_partner`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.Delivery_Partner{}
	for rows.Next() {
		partner, err := scan_Into_Delivery_Partner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}
	return partners, nil
}

// 3. Create a function to retrieve a delivery partner by phone
func (s *PostgresStore) Get_Delivery_Partner_By_Phone(phone int) (*types.Delivery_Partner, error) {
	rows, err := s.db.Query("select * from delivery_partner where phone = $1", phone)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.Delivery_Partner{}
	for rows.Next() {
		partner, err := scan_Into_Delivery_Partner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}

	if len(partners) == 0 {
		return nil, nil
	}
	return partners[0], nil
}

// 4. Helper function to scan rows into a delivery partner struct
func scan_Into_Delivery_Partner(rows *sql.Rows) (*types.Delivery_Partner, error) {
	partner := new(types.Delivery_Partner)
	err := rows.Scan(
		&partner.ID,
		&partner.Name,
		&partner.FCM_Token,
		&partner.Store_ID,
		&partner.Phone,
		&partner.Address,
		&partner.Created_At,
	)
	return partner, err
}
