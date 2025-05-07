# Otto Mart Store Manager

A multiplatform Flutter application for store managers to receive customer orders, process supplier shipments, and monitor & manage inventory and items in your store.

---

## Table of Contents

* [Features](#features)
* [Platforms](#platforms)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Directory Structure](#directory-structure)
* [Usage](#usage)
* [Configuration](#configuration)
* [Testing](#testing)
* [Building & Deployment](#building--deployment)
* [Contributing](#contributing)
* [License](#license)

---

## Features

* 🛒 **Order Management**: View and accept incoming customer orders in real time.
* 🚚 **Shipment Processing**: Receive and log shipments from suppliers, update stock levels.
* 📊 **Inventory Monitoring**: Track stock counts, low-stock alerts, and shelf organization.
* 🔎 **Item Management**: Add, edit, search, and categorize items.
* 🔄 **Vendor Management**: Browse vendor catalogs, manage vendor relationships.
* 📱 **Offline Support**: Gracefully handle network interruptions with offline caching.
* ⚙️ **Settings & Scanner**: Configure app preferences and use built‑in barcode scanner for faster item lookup.

## Platforms

* Android
* iOS
* Web
* macOS
* Windows
* Linux

## Prerequisites

* Flutter SDK (>=3.0.0)
* Dart SDK
* Android Studio / Xcode (for mobile builds)
* Chrome (for web)
* CMake & GTK (for desktop builds)

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-org/otto-mart-store-manager.git
   cd otto-mart-store-manager
   ```

2. **Fetch dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate platform plugins** (if needed)

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Directory Structure

```
.
├── android/           # Android project files
├── ios/               # iOS project files
├── lib/               # Main application code
│   ├── inventory/     # Inventory tracking screens & logic
│   ├── new-item/      # Add & configure new items (finance, scan)
│   ├── shelf/         # Shelf layout & shelf management UI
│   ├── store/         # Store listing, item detail, and category views
│   ├── utils/         # Constants, networking, offline handlers, scanner
│   └── vendor/        # Vendor listing & vendor dashboard
├── assets/            # App icons and image assets
├── test/              # Automated widget & integration tests
├── web/               # Web app configuration & static files
├── linux/, macos/, windows/  # Desktop build configurations
├── pubspec.yaml       # Project metadata & dependencies
└── README.md          # This file
```

## Usage

1. **Run on connected device or emulator**

   ```bash
   flutter run
   ```

2. **Specify platform**

   * Android: `flutter run -d android`
   * iOS: `flutter run -d ios`
   * Web: `flutter run -d chrome`
   * macOS: `flutter run -d macos`

3. **Hot reload**
   Press `r` in the console or use IDE shortcuts.

## Configuration

* **API Base URL**: Set in `lib/utils/constants.dart`.
* **Authentication**: Uses OTP flow; configure endpoints in `lib/utils/network/`.
* **Offline Cache**: SQLite or shared preferences; see `lib/utils/no_internet_api.dart`.

## Testing

* **Unit & Widget Tests**

  ```bash
  flutter test
  ```

* **Integration Tests** (requires a test device/emulator)

  ```bash
  flutter drive --target=test_driver/app.dart
  ```

## Building & Deployment

* **Android APK**

  ```bash
  flutter build apk --release
  ```

* **iOS IPA**

  ```bash
  flutter build ios --release
  ```

* **Web**

  ```bash
  flutter build web --release
  ```

* **Desktop**

  ```bash
  flutter build macos
  flutter build windows
  flutter build linux
  ```

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: \`git commit -m "Add feature"
4. Push branch: `git push origin feature/my-feature`
5. Open a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.
