package store

import (
	"database/sql"
	"pronto-go/types"

	_ "github.com/lib/pq"
)

func (s *PostgresStore) CreateDeliveryPartnerTable() error {
	//fmt.Println("Entered CreateItemTable")

	query := `create table if not exists delivery_partner(
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		store_id INT REFERENCES Store(id) ON DELETE CASCADE NOT NULL,
		phone VARCHAR(10) NOT NULL, 
		address TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := s.db.Exec(query)

	//fmt.Println("Exiting CreateItemTable")

	return err
}
// 1. Create a function to insert a new delivery partner
func (s *PostgresStore) Create_DeliveryPartner(dp *types.Create_DeliveryPartner) (*types.DeliveryPartner, error) {
	query := `insert into delivery_partner
	(name, store_id, phone, address) 
	values ($1, $2, $3, $4) returning id, name, store_id, phone, address, created_at
	`

	rows, err := s.db.Query(
		query,
		dp.Name,
		dp.Store_ID,
		dp.Phone,
		dp.Address,
	)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.DeliveryPartner{}
	for rows.Next() {
		partner, err := scan_Into_DeliveryPartner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}
	return partners[0], nil
}

// 2. Create a function to retrieve all delivery partners
func (s *PostgresStore) Get_All_DeliveryPartners() ([]*types.DeliveryPartner, error) {
	query := `select * from delivery_partner`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.DeliveryPartner{}
	for rows.Next() {
		partner, err := scan_Into_DeliveryPartner(rows)
		if err != nil {
			return nil, err
		}
		partners = append(partners, partner)
	}
	return partners, nil
}

// 3. Create a function to retrieve a delivery partner by phone
func (s *PostgresStore) Get_DeliveryPartner_By_Phone(phone string) (*types.DeliveryPartner, error) {
	rows, err := s.db.Query("select * from delivery_partner where phone = $1", phone)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	partners := []*types.DeliveryPartner{}
	for rows.Next() {
		partner, err := scan_Into_DeliveryPartner(rows)
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
func scan_Into_DeliveryPartner(rows *sql.Rows) (*types.DeliveryPartner, error) {
	partner := new(types.DeliveryPartner)
	err := rows.Scan(
		&partner.ID,
		&partner.Name,
		&partner.Store_ID,
		&partner.Phone,
		&partner.Address,
		&partner.Created_At,
	)
	return partner, err
}
