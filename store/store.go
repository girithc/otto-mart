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
	// fmt.Println("Entered Init() -- db.go")

	errCategory := s.Create_Category_Table()
	if errCategory != nil {
		return errCategory
	} else {
		fmt.Println("Success - Created Category Table")
	}

	errStore := s.CreateStoreTable()
	if errStore != nil {
		return errStore
	} else {
		fmt.Println("Success - Created Store Table")
	}

	errItem := s.CreateItemTable()
	if errItem != nil {
		return errItem
	} else {
		fmt.Println("Success - Created Item Table")
	}

	errItemCategory := s.CreateItemCategoryTable()
	if errItemCategory != nil {
		return errItemCategory
	} else {
		fmt.Println("Success - Created Item Category Table")
	}

	errItemImage := s.CreateItemImageTable()
	if errItemImage != nil {
		return errItemImage
	} else {
		fmt.Println("Success - Created Item Image Table")
	}

	errItemStore := s.CreateItemStoreTable()
	if errItemStore != nil {
		return errItemStore
	} else {
		fmt.Println("Success - Created Item Store Table")
	}

	errCustomer := s.CreateCustomerTable()
	if errCustomer != nil {
		return errCustomer
	} else {
		fmt.Println("Success - Created Customer Table")
	}

	errAddressTable := s.CreateAddressTable()
	if errAddressTable != nil {
		return errAddressTable
	} else {
		fmt.Println("Success - Created Address Table")
	}

	errCartItem := s.CreateCartItemTable()
	if errCartItem != nil {
		return errCartItem
	} else {
		fmt.Println("Success - Created Cart Item Table")
	}

	errHigherLevelCategory := s.CreateHigherLevelCategoryTable()
	if errHigherLevelCategory != nil {
		return errHigherLevelCategory
	} else {
		fmt.Println("Success - Created Higher Level Category Table")
	}

	errCategoryHigherLevelMapping := s.Create_Category_Higher_Level_Mapping_Table()
	if errCategoryHigherLevelMapping != nil {
		return errCategoryHigherLevelMapping
	} else {
		fmt.Println("Success - Created Category Higher Level Mapping Table")
	}

	errDeliveryPartner := s.CreateDeliveryPartnerTable()
	if errDeliveryPartner != nil {
		return errDeliveryPartner
	} else {
		fmt.Println("Success - Created Delivery Partner Table")
	}

	errShoppingCart := s.CreateShoppingCartTable()
	if errShoppingCart != nil {
		return errShoppingCart
	} else {
		fmt.Println("Success - Created Shopping Cart Table")
	}

	errSetCartItemFKs := s.SetCartItemForeignKeys()
	if errSetCartItemFKs != nil {
		return errSetCartItemFKs
	}

	errSalesOrder := s.CreateSalesOrderTable()
	if errSalesOrder != nil {
		return errSalesOrder
	} else {
		fmt.Println("Success  - Created Sales Order Table")
	}

	// Check and add the constraint only if it doesn't exist
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

	if _, err := s.db.Exec(constraintQuery); err != nil {
		return fmt.Errorf("failed to add constraint to shopping_cart: %w", err)
	}

	// ... [your other code, if any]

	return nil
}
