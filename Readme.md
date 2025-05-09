# Master Repository: Otto-Mart

## Introduction

This master repository, named **Otto-Mart**, consolidates multiple individual repositories into one unified project. The merged repositories include various microservices, mobile applications, and supporting automation tools, aimed at creating a comprehensive e-commerce and delivery ecosystem.

## Repository Structure

The repository is organized into the following main components:

### 1. Customer Shopping

* A mobile application for customer shopping experience.
* Contains code for Android, iOS, and Web.
* Built using Flutter and Dart.
* Key directories: `lib/`, `assets/`, `android/`, `ios/`, `web/`, `test/`.

### 2. Server

* Backend server handling API requests and database operations.
* Built using Golang.
* Key directories: `api/`, `store/`, `types/`, `worker/`.
* Uses Firebase for notifications and PostgreSQL for data storage.

### 3. Delivery

* A mobile application dedicated to delivery partners.
* Built using Flutter and Dart.
* Key directories: `lib/`, `assets/`, `android/`, `ios/`, `web/`, `test/`.

### 4. Packer

* A mobile application for packing and logistics management.
* Built using Flutter and Dart.
* Key directories: `lib/`, `assets/`, `android/`, `ios/`, `web/`, `test/`.

### 5. Store Manager

* A mobile application for store inventory and management.
* Built using Flutter and Dart.
* Key directories: `lib/`, `assets/`, `android/`, `ios/`, `web/`, `test/`.

### 6. Invoice Automation

* Scripts for automated invoice generation and vendor management.
* Uses Python for scripting.

## Installation

Each component has its own setup and dependencies. Refer to individual component README files for detailed installation steps.

## Usage

### Running the Mobile Applications

1. Navigate to the respective app directory (e.g., `customer-shopping`).
2. Use Flutter to build and run the app:

   ```bash
   flutter run
   ```

### Running the Backend Server

1. Navigate to the `server/` directory.
2. Run the Go server:

   ```bash
   go run main.go
   ```

## Contributing

Please follow the contribution guidelines and open a pull request for any changes. Make sure to run tests and format your code before submitting.

## License

This project is licensed under the MIT License.
