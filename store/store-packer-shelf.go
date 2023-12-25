package store

import "database/sql"

func (s *PostgresStore) CreatePackerShelfTable(tx *sql.Tx) error {
	query := `
    CREATE TABLE IF NOT EXISTS Packer_Shelf (
        id SERIAL PRIMARY KEY,
        sales_order_id INT REFERENCES Sales_Order(id) ON DELETE CASCADE,
        packer_id INT REFERENCES Packer(id) ON DELETE CASCADE,
        shelf_id INT REFERENCES Shelf(shelf_id) ON DELETE CASCADE,
        active BOOLEAN NOT NULL DEFAULT true,
        drop_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        pickup_time TIMESTAMP
    );

    CREATE OR REPLACE FUNCTION update_active()
    RETURNS TRIGGER AS $$
    BEGIN
        IF NEW.pickup_time IS NOT NULL THEN
            NEW.active := false;
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_update_active
    BEFORE UPDATE ON Packer_Shelf
    FOR EACH ROW
    EXECUTE FUNCTION update_active();

    CREATE UNIQUE INDEX idx_unique_active_shelf ON Packer_Shelf(shelf_id) WHERE active;
    `

	_, err := tx.Exec(query)
	return err
}
