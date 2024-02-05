package store

import "database/sql"

func (s *PostgresStore) AuthenticateRequest(phone, token string) (bool, string, error) {
	query := `SELECT token, role FROM customer WHERE phone = $1`

	var dbToken sql.NullString
	var role string

	err := s.db.QueryRow(query, phone).Scan(&dbToken, &role)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, "", nil
		}
		return false, "", err
	}

	if dbToken.Valid && dbToken.String == token && len(role) > 0 {
		return true, role, nil
	}

	return false, "", nil
}
