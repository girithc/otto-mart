package store

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"

	"cloud.google.com/go/cloudsqlconn"
	"cloud.google.com/go/cloudsqlconn/postgres/pgxv4"
	_ "github.com/lib/pq"
)

type PostgresStore struct {
	db          *sql.DB
	cancelFuncs map[int]context.CancelFunc
}

func NewPostgresStore() (*PostgresStore, func() error) {
	// Check the runtime environment
	runEnv := os.Getenv("RUN_ENV")

	if runEnv == "LOCAL" {
		// Use local credentials
		// connStr := "host=host.docker.internal user=postgres dbname=prontodb password=g190201 sslmode=disable"
		// db, err = sql.Open("postgres", connStr)

		connStr := "user=postgres dbname=prontodb password=g190201 sslmode=disable"
		db, err := sql.Open("postgres", connStr)
		if err != nil {
			log.Fatalf("(local) Error on sql.Open: %v", err)
		}
		return &PostgresStore{
			db:          db,
			cancelFuncs: make(map[int]context.CancelFunc), // Initialize the cancelFuncs map
		}, nil
	} else {
		// Use Cloud SQL credentials
		cleanup, err := pgxv4.RegisterDriver("cloudsql-postgres", cloudsqlconn.WithIAMAuthN())
		if err != nil {
			log.Fatalf("Error on pgxv4.RegisterDriver: %v", err)
		}

		dsn := fmt.Sprintf("host=%s user=%s dbname=%s password=%s sslmode=disable", os.Getenv("INSTANCE_CONNECTION_NAME"), os.Getenv("DB_USER"), os.Getenv("DB_NAME"), os.Getenv("DB_PASSWORD"))
		db, err := sql.Open("cloudsql-postgres", dsn)
		if err != nil {
			log.Fatalf("Error on sql.Open: %v", err)
		}

		/*
				connStr := "host=host.docker.internal user=postgres dbname=prontodb password=g190201 sslmode=disable"
				db, err := sql.Open("postgres", connStr)
				if err != nil {
					log.Fatalf("Error on sql.Open: %v", err)
				}

			if err := db.Ping(); err != nil {
				log.Fatalf("Error on db.Ping(). Db connection error: %v", err)
			}
		*/
		return &PostgresStore{
			db:          db,
			cancelFuncs: make(map[int]context.CancelFunc), // Initialize the cancelFuncs map
		}, cleanup
	}
}

func (s *PostgresStore) Init() error {
	// Start a new transaction
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	// Define a deferred function to handle the transaction's commit or rollback
	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			tx.Commit()
		}
	}()

	if err := s.Create_Category_Table(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Category Table")

	if err := s.Create_Category_Image_Table(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Category_Image Table")

	if err := s.CreateStoreTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Store Table")

	if err := s.CreateBrandTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Brand Table")

	if err := s.CreateItemTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Table")

	if err := s.CreateItemCategoryTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Category Table")

	if err := s.CreateItemImageTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Image Table")

	if err := s.CreateItemStoreTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Store Table")

	if err := s.CreateCustomerTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Customer Table")

	if err := s.CreateAddressTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Address Table")

	if err := s.CreateCartItemTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Cart Item Table")

	if err := s.CreateHigherLevelCategoryTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Higher Level Category Table")

	if err := s.CreateHigherLevelCategoryImageTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Higher Level Category Image Table")

	if err := s.Create_Category_Higher_Level_Mapping_Table(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Category Higher Level Mapping Table")

	if err := s.CreateDeliveryPartnerTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Delivery Partner Table")

	if err := s.CreateShoppingCartTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Shopping Cart Table")

	if err := s.SetCartItemForeignKeys(tx); err != nil {
		return err
	}

	if err := s.CreateSalesOrderTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Sales Order Table")

	constraintQuery := `
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT constraint_name 
            FROM information_schema.table_constraints 
            WHERE table_name = 'shopping_cart' AND constraint_name = 'shopping_cart_order_id_fkey'
        ) THEN
            ALTER TABLE shopping_cart ADD CONSTRAINT shopping_cart_order_id_fkey FOREIGN KEY (order_id) REFERENCES sales_order(id) ON DELETE CASCADE;
        END IF;
    END
    $$;
    `
	if _, err := tx.Exec(constraintQuery); err != nil {
		return fmt.Errorf("failed to add constraint to shopping_cart: %w", err)
	}

	return nil
}
