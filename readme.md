# Otto Mart Server

A fully functional Go backend powering **Otto Mart**, an e-commerce platform with end-to-end features:

* ✅ **User Authentication**: OTP-based login for customers, packers, delivery partners, and managers.
* 📦 **Inventory Management**: CRUD operations for items, brands, categories, shelving, stock locking.
* 🛒 **Shopping Cart & Checkout**: Cart management, checkout initiation, payment integration with PhonePe, and payment verification.
* 🚚 **Order & Delivery Workflow**: Sales order creation, assignment to packers, dispatch, tracking, and delivery partner operations.
* ⚙️ **Concurrency & Background Tasks**: Worker pool implementation for handling asynchronous tasks (invoicing, notifications, stock locks) efficiently.
* 🔄 **Cloud Tasks**: Integration with Google Cloud Tasks for reliable, retriable background processing.
* 🗄️ **Database**: Supabase (PostgreSQL) for data persistence.
* 🐳 **Containerization & Deployment**: Docker image on Google Cloud Run for scalable, serverless deployment.

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Prerequisites](#prerequisites)
3. [Setup & Installation](#setup--installation)
4. [Configuration](#configuration)
5. [File Structure](#file-structure)
6. [Running the Server](#running-the-server)
7. [API Endpoints](#api-endpoints)
8. [Worker Pool & Background Tasks](#worker-pool--background-tasks)
9. [Database Schema](#database-schema)
10. [Deployment](#deployment)
11. [Testing](#testing)
12. [Contributing](#contributing)
13. [License](#license)

---

## Tech Stack

* **Language**: Go 1.20+
* **Database**: Supabase (PostgreSQL)
* **Concurrency**: Custom `WorkerPool` for background jobs
* **Messaging**: Google Cloud Tasks (queues for async processing)
* **Containerization**: Docker
* **Hosting**: Google Cloud Run

## Prerequisites

* Go 1.20 or newer
* Docker
* Supabase project with URL & service role key
* Google Cloud account with Cloud Run & Cloud Tasks enabled

## Setup & Installation

```bash
# Clone
git clone https://github.com/your-org/otto-mart-server.git
cd otto-mart-server

# Fetch dependencies
go mod download
```

## Configuration

Copy the example environment file and populate:

```bash
cp .env.example .env
```

```env
# Supabase
SUPABASE_URL=<your-supabase-url>
SUPABASE_KEY=<your-service-role-key>

# JWT
JWT_SECRET=<your-jwt-secret>

# PhonePe
PHONEPE_MERCHANT_ID=<merchant-id>
PHONEPE_SECRET=<merchant-secret>

# Google Cloud
GCLOUD_PROJECT=<project-id>
GCLOUD_REGION=<region>
CLOUD_TASKS_QUEUE=<queue-name>
```

## File Structure

```
.
├── api/                # HTTP handlers and routing
│   └── handle-*.go
├── store/              # Database access layer
│   └── store-*.go
├── types/              # Shared DTOs & models
├── worker/             # Background workers & WorkerPool
│   ├── worker-pool.go
│   └── http.go         # Task HTTP endpoints
├── Dockerfile
├── go.mod, go.sum      # Go modules
├── main.go             # Entry point: initializes Server & WorkerPool
└── readme.md           # This file
```

## Running the Server

### Locally

```bash
go run main.go
# Server listens on :8080 by default
```

### With Docker

```bash
docker build -t otto-mart-server .
docker run -p 8080:8080 --env-file .env otto-mart-server
```

## API Endpoints

| Method | Path                                                                                         | Description                   |
| ------ | -------------------------------------------------------------------------------------------- | ----------------------------- |
| POST   | `/send-otp`                                                                                  | Send OTP to phone             |
| POST   | `/verify-otp`                                                                                | Verify OTP & issue JWT        |
| GET    | `/api/items`                                                                                 | List all items                |
| POST   | `/api/items`                                                                                 | Create new item               |
| PUT    | `/api/items/{id}`                                                                            | Update item                   |
| DELETE | `/api/items/{id}`                                                                            | Delete item                   |
| POST   | `/shopping-cart`                                                                             | Add or update cart items      |
| GET    | `/shopping-cart`                                                                             | Retrieve cart details         |
| POST   | `/checkout-payment`                                                                          | Initiate checkout & payment   |
| POST   | `/payment-verify`                                                                            | Payment verification callback |
| GET    | `/sales-order`                                                                               | List orders                   |
| POST   | `/sales-order/{id}/cancel`                                                                   | Cancel an order               |
| …      | *More endpoints for brands, categories, users, packers, delivery partners, manager actions.* |                               |

## Worker Pool & Background Tasks

The `worker` package implements a `WorkerPool` to process jobs concurrently:

* **Task Submission**: Handlers enqueue tasks (e.g., invoice generation, stock unlocking) to the pool.
* **Concurrency**: Configurable number of workers consume jobs from a channel.
* **Cloud Tasks Integration**: For cross-service reliability, jobs can also be dispatched via Google Cloud Tasks HTTP endpoints in `worker/http.go`.

```go
wp := worker.NewWorkerPool(maxWorkers)
go wp.Run()

// In handler:
wp.Enqueue(job)
```

## Database Schema

Managed via Supabase migrations. Models are defined in `types/` and table logic in `store/`.

## Deployment

1. **Build & Push Docker Image**

   ```bash
   ```

gcloud builds submit --tag gcr.io/\$GCLOUD\_PROJECT/otto-mart-server

````

2. **Deploy to Cloud Run**
```bash
gcloud run deploy otto-mart-server \
--image gcr.io/$GCLOUD_PROJECT/otto-mart-server \
--region $GCLOUD_REGION \
--set-env-vars SUPABASE_URL=$SUPABASE_URL,... \
--platform managed
````

3. **Configure Cloud Tasks**

   ```bash
   ```

gcloud tasks queues create \$CLOUD\_TASKS\_QUEUE --project=\$GCLOUD\_PROJECT --location=\$GCLOUD\_REGION

````

## Testing

- **Unit Tests**
```bash
go test ./... -v
````

* **Integration Tests**
  Use a separate Supabase test instance and mock payment callbacks.

## Contributing

1. Fork & clone
2. Create feature branch (`git checkout -b feature/foo`)
3. Commit changes
4. Push & open PR

## License

MIT. See [LICENSE](LICENSE) for details.
