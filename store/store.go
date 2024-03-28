package store

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"

	"cloud.google.com/go/cloudsqlconn"
	"cloud.google.com/go/cloudsqlconn/postgres/pgxv4"
	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"google.golang.org/api/option"

	_ "github.com/lib/pq"
)

type PostgresStore struct {
	db             *sql.DB
	cancelFuncs    map[int]context.CancelFunc
	lockExtended   map[int]bool
	paymentStatus  map[int]bool
	firebaseClient *messaging.Client
	context        context.Context
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
		cleanup, err := pgxv4.RegisterDriver("cloudsql-postgres", cloudsqlconn.WithIAMAuthN())
		if err != nil {
			log.Fatalf("Error on pgxv4.RegisterDriver: %v", err)
		}

		dsn := fmt.Sprintf("host=%s user=%s dbname=%s password=%s sslmode=disable", os.Getenv("INSTANCE_CONNECTION_NAME"), os.Getenv("DB_USER"), os.Getenv("DB_NAME"), os.Getenv("DB_PASSWORD"))
		db, err := sql.Open("cloudsql-postgres", dsn)
		if err != nil {
			log.Fatalf("Error on sql.Open: %v", err)
		}

		const firebaseConfig = `{
			"type": "service_account",
			"project_id": "seismic-ground-410711",
			"private_key_id": "4da78ed26c721c31d5966a1dc8e67abb21e80c22",
			"private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDESeFAV07sOozN\nwfxg9XikDNWj/GFI5CO/TvPe1LLVxye82m1tSwmSQ181zRzQ7IeZCZ7fzGV0WXeC\nwd0OMdwgsOYlcgtSb5N/Evw28W1c+Q3S+ePv1ZDsc9pIOX1qOKUCDO8xxgu4d/GU\nuIsEIc7fwvLxBep/twoR6KKgAK22UE2QCo42j26CyUX+191KZo4XbyOk0TlR+Fyc\nDRuQ7PTIVwWy6iEGjzHtYB5VF8+GniBLZ+33iHF1kijCiQ9GIW49tZutixFlv0AD\nEstcYh/BibISlRCZN3VDbKFzzA4a6YFf4LIfi7QfrmkXHPQrbkXfoOIDa1SCfYXH\nowl/kFKzAgMBAAECggEAAi0kQNp29upHo2F69eCdDkVQtFwe0dVCFmO+thlSiexv\ndEQi/wI5V8L+7EA+CUb6dS2nrKkyUgwE/RycPu30OvPVV/bxSWA/JIBdqMx5Ygkm\nVug6NKm6KhT88FD5aOpdI3QLn53thVcUM6FLdDN02gMv+L8+rnQCdB5hBE+Ahks2\nThhobZ0+unwMI+5zZd3B2l+kjR26KSGF0eSkneMf5k7kYOe3f/nlSJWYddNOGQcG\nvIHrzws/wiExv9X+VaNc1PbK1PIfAsefXqJg9gViINCWTHLEhZnICvYd1vyQ3PJ5\nZnYH0EHgIyMkwGjXJi83y6Doef1LUNYnXz+SRubvqQKBgQDjOV44cj2rf4Yz+6fR\n/ZHb3McuGhynDyQsoWl+ui9gYLfUd1c/0ykgl2bpxL8c9uEoSUiNSWeKivnsxiUe\n322GcIjrrZKd2rzgA7D8zuTNr3zS20lDmyK4nVxxHs+wyL7nj2MuJ2ShCGyAZbbb\nxlg4ivoAhvbJWaiAxbpMs+QEJwKBgQDdJZRKKjg19eOhgWTe1GIBtWesYPBVjco2\nRSpVxiUjKU37yQo7ycJQIkI+20+IU9WFeuzCDsTLhvCsniiQKJxsaRddXR/kowgF\n+O/dl9dlFuQHPRHfX/rbEeCiF1lc4k1CyPja0vMVCkBQjqHKdkB/DV2o5Y5QkPMu\nNsZ5f3/YlQKBgFMbTmzSy9+H+uvUZWMWnVyO+YLRJh2sGg0A1Hb3XhCgD1x0ccL0\nVpyHA6sIvOW5Hkz/0LtsV6SChDqnljgefA6p5kpc5704ndBJSViNy323a64rajaB\n7UcctwzguhHsunYzKZFd8x462IR1r1Xey7GSkzHSKz0lv82phCQ9v24NAoGBAI/5\nhkieogfndPJR1oUICmKIYt2kIvPgIvUgJIbBQK5als3Evifcm+gl1bEsgOQFiG6l\nb/yLNu42hPws38Wy2tvts2tyVHA6/987iZZf47iJpZ1c0gT2bNAxHGkLAH/rSVeg\nlfuI+P8KtIJ9ybGROT4+SmrKQNQM+nVs7dxt+KLdAoGALQaLiZFnS9kYKHNeLjxT\ngIAwHMefV1ACbKmC3+/O02bvMvvq05k37DPBkk3HN5ofCOxtvv/qLO9ADIwBan7u\n/VOvn6daQp/hsUcmSgUDsOpDi1vCjUgQi0Pvvw9jDI0QtS7yIGQOnKrPmRvirsDK\nG+mGRtytq1Wa1uBLTKefojM=\n-----END PRIVATE KEY-----\n",
			"client_email": "firebase-adminsdk-jac9l@seismic-ground-410711.iam.gserviceaccount.com",
			"client_id": "116694554962825676164",
			"auth_uri": "https://accounts.google.com/o/oauth2/auth",
			"token_uri": "https://oauth2.googleapis.com/token",
			"auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
			"client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-jac9l%40seismic-ground-410711.iam.gserviceaccount.com",
			"universe_domain": "googleapis.com"
		  }
		  `

		wd, err := os.Getwd()
		if err != nil {
			fmt.Println("Error:", err)
		}
		fmt.Println("Working Directory:", wd)
		//opt := option.WithCredentialsFile("/seismic-ground-410711-firebase-adminsdk-jac9l-4da78ed26c.json")

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

		return &PostgresStore{
			db:             db,
			cancelFuncs:    make(map[int]context.CancelFunc), // Already initialized cancelFuncs map
			lockExtended:   make(map[int]bool),               // Initialize the paymentStatus map
			paymentStatus:  make(map[int]bool),
			firebaseClient: client,
			context:        ctx,
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
