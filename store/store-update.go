package store

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/girithc/pronto-go/types"
)

func (s *PostgresStore) CreateUpdateAppTable(tx *sql.Tx) error {
	// Define the ENUM type for platform
	platformEnumQuery := `DO $$ BEGIN
                            CREATE TYPE platform_enum AS ENUM ('ios', 'android', 'web');
                        EXCEPTION
                            WHEN duplicate_object THEN null;
                        END $$;`
	_, err := tx.Exec(platformEnumQuery)
	if err != nil {
		return fmt.Errorf("error creating platform_enum type: %w", err)
	}

	// Create the updateapp table with updated_at, maintenance, and maintenance_end_time columns
	createTableQuery := `CREATE TABLE IF NOT EXISTS updateapp(
        id SERIAL PRIMARY KEY,
        build_number VARCHAR(50) NOT NULL,
        version_number VARCHAR(50) NOT NULL,
        package_name VARCHAR(255) NOT NULL,
        platform platform_enum NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        maintenance BOOLEAN DEFAULT false,
        maintenance_end_time TIMESTAMP
    )`
	_, err = tx.Exec(createTableQuery)
	if err != nil {
		return fmt.Errorf("error creating updateapp table: %w", err)
	}

	// Create a unique index on package_name and platform
	createUniqueIndexQuery := `CREATE UNIQUE INDEX IF NOT EXISTS updateapp_package_platform_unique ON updateapp (LOWER(package_name), platform);`
	_, err = tx.Exec(createUniqueIndexQuery)
	if err != nil {
		return fmt.Errorf("error creating unique index for package_name and platform: %w", err)
	}

	return nil
}

func (s *PostgresStore) NeedToUpdate(newReq *types.UpdateApp) (*UpdateResponse, error) {
	fmt.Println("Inside NeedToUpdate")
	fmt.Println("New Request: ", newReq.BuildNo, newReq.Version, newReq.Platform)

	var versionNumber, buildNumber string
	var maintenance bool
	var maintenanceEndTime sql.NullTime // Use sql.NullTime to handle NULL values

	// Updated query to select maintenance and maintenance_end_time
	query := `SELECT version_number, build_number, maintenance, maintenance_end_time FROM updateapp WHERE package_name = $1 AND platform = $2 ORDER BY updated_at DESC LIMIT 1`
	err := s.db.QueryRow(query, newReq.PackageName, newReq.Platform).Scan(&versionNumber, &buildNumber, &maintenance, &maintenanceEndTime)
	if err != nil {
		if err == sql.ErrNoRows {
			// No records found, possibly a new app, needs to update
			return &UpdateResponse{UpdateRequired: false, MaintenanceRequired: true, MaintenanceEndTime: time.Now().Add(6 * time.Hour)}, nil
		}
		// Handle other potential errors
		return nil, fmt.Errorf("error querying updateapp table: %w", err)
	}

	fmt.Println("New Request: ", newReq.BuildNo, newReq.Version, newReq.Platform)

	fmt.Println("Build Number: ", buildNumber)
	fmt.Println("Version Number: ", versionNumber)
	fmt.Println("Maintenance: ", maintenance)

	// Initialize the default response to no update required and check for maintenance
	updateResponse := &UpdateResponse{
		UpdateRequired:      false,
		MaintenanceRequired: maintenance,
	}

	// Handle maintenance end time (only if not NULL)
	if maintenanceEndTime.Valid {
		updateResponse.MaintenanceEndTime = maintenanceEndTime.Time
	}

	// Compare version numbers
	if newReq.Version > versionNumber {
		// New request has a higher version, no need to update
		return updateResponse, nil
	} else if newReq.Version == versionNumber {
		if newReq.Platform == "ios" {
			// For iOS, equal version number means no update needed
			return updateResponse, nil
		} else {
			// For Android and Web, need to check build numbers
			if newReq.BuildNo > buildNumber {
				// Build number is higher, no need to update
				return updateResponse, nil
			}
		}
	}

	// If none of the above conditions are met, an update is needed
	updateResponse.UpdateRequired = true
	return updateResponse, nil
}

type UpdateResponse struct {
	UpdateRequired      bool      `json:"update_required"`
	MaintenanceRequired bool      `json:"maintenance_required"`
	MaintenanceEndTime  time.Time `json:"end_time"`
}
