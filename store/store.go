package store

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"firebase.google.com/go/storage"
	"google.golang.org/api/option"

	_ "github.com/lib/pq"
	"github.com/supabase-community/supabase-go"
)

type PostgresStore struct {
	db                *sql.DB
	db2               *sql.DB
	cancelFuncs       map[int]context.CancelFunc
	lockExtended      map[int]bool
	paymentStatus     map[int]bool
	firebaseMessaging *messaging.Client
	firebaseStorage   *storage.Client
	context           context.Context
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
			db:            db,
			cancelFuncs:   make(map[int]context.CancelFunc), // Already initialized cancelFuncs map
			lockExtended:  make(map[int]bool),               // Initialize the paymentStatus map
			paymentStatus: make(map[int]bool),
		}, nil
	} else {
		// Use Cloud SQL credentials

		/*
			cleanup, err := pgxv4.RegisterDriver("cloudsql-postgres", cloudsqlconn.WithIAMAuthN())
			if err != nil {
				log.Fatalf("Error on pgxv4.RegisterDriver: %v", err)
			}

			dsn := fmt.Sprintf("host=%s user=%s dbname=%s password=%s sslmode=disable", os.Getenv("INSTANCE_CONNECTION_NAME"), os.Getenv("DB_USER"), os.Getenv("DB_NAME"), os.Getenv("DB_PASSWORD"))
			db, err := sql.Open("cloudsql-postgres", dsn)
			if err != nil {
				log.Fatalf("Error on sql.Open: %v", err)
			}
		*/
		const firebaseConfig = `{
			
		  }
		  `

		wd, err := os.Getwd()
		if err != nil {
			fmt.Println("Error:", err)
		}
		fmt.Println("Working Directory:", wd)
		// opt := option.WithCredentialsFile("/seismic-ground-410711-firebase-adminsdk-jac9l-4da78ed26c.json")

		opt := option.WithCredentialsJSON([]byte(firebaseConfig))

		projectID := "seismic-ground-410711"

		// Initialize Firebase app with project ID
		app, err := firebase.NewApp(context.Background(), &firebase.Config{
			ProjectID: projectID,
		}, opt)
		if err != nil {
			log.Fatalf("error initializing app: %v\n", err)
		}

		println("Firebase app initialized")

		// Obtain a messaging.Client from the App.
		ctx := context.Background()
		client, err := app.Messaging(ctx)
		if err != nil {
			log.Fatalf("error getting Messaging client: %v\n", err)
		}

		clientStorage, err := app.Storage(ctx)
		if err != nil {
			log.Fatalf("error getting Messaging client: %v\n", err)
		}

		supaClient, err := supabase.NewClient()
		if err != nil {
			log.Fatalf("cannot initialize Supabase client: %v", err)
		}

		// Fetching data from Supabase for verification
		data, count, err := supaClient.From("countries").Select("*", "exact", false).Execute()
		if err != nil {
			fmt.Println("error executing Supabase query", err)
		} else {
			fmt.Printf("Fetched %d records from Supabase: %v\n", count, data)
		}

		// Use Supabase connection string
		connStr := fmt.Sprintf(
		)

		db2, err := sql.Open("postgres", connStr)
		if err != nil {
			log.Fatalf("Error on sql.Open: %v", err)
		}

		return &PostgresStore{
			db:                db2,
			db2:               db2,
			cancelFuncs:       make(map[int]context.CancelFunc), // Already initialized cancelFuncs map
			lockExtended:      make(map[int]bool),               // Initialize the paymentStatus map
			paymentStatus:     make(map[int]bool),
			firebaseMessaging: client,
			firebaseStorage:   clientStorage,
			context:           ctx,
		}, nil

	}
}

func (s *PostgresStore) Init() error {
	// Start a new transaction
	tx, err := s.db2.Begin()
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

	if err := s.CreateCartItemTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Cart Item Table")

	if err := s.CreateAddressTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Address Table")

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

	if err := s.CreateSlotTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Slot Table")

	if err := s.CreateDeliveryDistanceTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Delivery Distance Table")

	if err := s.CreateShoppingCartTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Shopping Cart Table")

	if err := s.CreatePackerTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Packer Table")

	if err := s.CreateSalesOrderTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Sales Order Table")

	if err := s.CreateOrderTimelineTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Order Timeline Table")

	if err := s.CreatePackerItemTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Packer Item Table")

	if err := s.CreateTransactionTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Transaction Table")

	if err := s.SetCartItemForeignKey(tx); err != nil {
		return err
	}

	if err := s.SetSalesOrderForeignKey(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Cart Item Foreign Key")

	if err := s.CreateShelfTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Shelf Table")

	if err := s.CreateDeliveryShelfTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Delivery Shelf Table")

	if err := s.CreatePackerShelfTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Packer Shelf Table")

	if err := s.CreateCartLockTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Cart Lock Table")

	if err := s.CreateDeliveryOrderTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Delivery Order Table")

	if err := s.CreateVendorTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Vendor Order Table")

	if err := s.CreateVendorBrandTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Vendor Brand Table")

	if err := s.CreateUpdateAppTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Update App Table")

	if err := s.CreateTaxTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Tax Table")

	if err := s.CreateItemTaxTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Tax Table")

	if err := s.CreateItemSchemeTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Scheme Table")

	if err := s.CreateItemFinancialTable(tx); err != nil {
		return err
	}
	fmt.Println("Success - Created Item Financial Table")
	if err := s.CreateManagerTable(tx); err != nil {
		return err
	}

	fmt.Println("Success - Created Sales Order OTP  Table")
	if err := s.CreateSalesOrderOtpTable(tx); err != nil {
		return err
	}

	fmt.Println("Success - Created Item Financial Table")

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
