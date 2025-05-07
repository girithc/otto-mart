# Otto Mart Packer App

A Flutter mobile application for store packers to manage and fulfill customer orders efficiently. The app provides real-time order assignments, item locating via shelf maps, barcode scanning for verification, and updates order status to notify delivery drivers. Firebase Cloud Messaging (FCM) is used for notifications.

---

## Table of Contents

* [Features](#features)
* [Platforms](#platforms)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Project Structure](#project-structure)
* [Configuration](#configuration)
* [Running the App](#running-the-app)
* [Testing](#testing)
* [Building & Deployment](#building--deployment)
* [Contributing](#contributing)
* [License](#license)

---

## Features

* 📦 **Order Assignments**: Receive and view active customer orders.
* 🗺️ **Item Location**: Display shelf location of each item for quick retrieval.
* 📲 **Barcode Scanning**: Scan items to verify correct picks using the device camera.
* 🔄 **Order Status Updates**: Update order stages (picked, packed) to trigger delivery notifications.
* 🔔 **Real-time Notifications**: Push notifications via Firebase Cloud Messaging for new orders and status changes.
* 🌐 **Offline Support**: Cache data and queue actions when offline, synchronizing when connection is restored.

## Platforms

* Android
* iOS

*(Codebase includes web, macOS, Linux, and Windows folders, but primary targets are mobile.)*

## Prerequisites

* Flutter SDK >= 3.0.0
* Dart SDK
* Android Studio (for Android builds)
* Xcode (for iOS builds)
* Firebase project with Cloud Messaging enabled

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-org/otto-mart-packer.git
   cd otto-mart-packer
   ```

2. **Fetch Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   * Place your `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) files in the respective `ios/` and `android/app/` directories.
   * Update `lib/firebase_options.dart` with your Firebase settings (run `flutterfire configure` if using FlutterFire CLI).

## Project Structure

```
.
├── android/         # Android native project & config
├── ios/             # iOS native project & config
├── lib/             # Flutter app code
│   ├── add-item/    # UI & logic to add items to orders
│   ├── delivery/    # Delivery page UI
│   ├── load/        # Load items & barcode listening
│   ├── pack/        # Packing workflows & scanners
│   ├── shelf/       # Shelf maps & location UI
│   ├── stock/       # Stock addition screens
│   ├── store/       # Store selection & item details
│   └── utils/       # Constants, networking, offline, settings
├── assets/          # Icons and images (scooters, app icon)
├── firebase_options.dart # Generated Firebase config
├── pubspec.yaml     # Dependencies & metadata
├── test/            # Widget & unit tests
└── README.md        # This file
```

## Configuration

* **API Base URL**: Set in `lib/utils/constants.dart`.
* **Firebase Options**: Managed in `lib/firebase_options.dart`.
* **FCM**: Permissions and handlers in `lib/utils/network/`.

## Running the App

1. **Connect a device or start an emulator**

2. **Run**

   ```bash
   flutter run
   ```

3. **Specify target**

   * Android: `-d android`
   * iOS: `-d ios`

4. **Hot reload** with `r` or IDE shortcut

## Testing

* **Unit & Widget Tests**

  ```bash
  flutter test
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

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m "Add my feature"`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.
