# Otto Mart Shopping App

A Flutter multiplatform application that powers the customer-facing side of **Otto Mart**. Shoppers can browse catalogs, place orders, and pay securely via OTP, Razorpay, or PhonePe. Integrated with Google Maps for address selection and Firebase Cloud Messaging for promotional push notifications. Deployed to production with over **200 active customers**.

---

## Table of Contents

* [Features](#features)
* [Tech Stack](#tech-stack)
* [Prerequisites](#prerequisites)
* [Setup & Installation](#setup--installation)
* [Configuration](#configuration)
* [Project Structure](#project-structure)
* [Usage](#usage)
* [Payments](#payments)
* [Maps & Address](#maps--address)
* [Notifications](#notifications)
* [Testing](#testing)
* [Deployment](#deployment)
* [Contributing](#contributing)
* [License](#license)

---

## Features

* 👤 **OTP Authentication**: Phone number login & verification.
* 🛍️ **Catalog & Search**: Browse categories, search products, view details.
* 🛒 **Cart & Orders**: Add to cart, checkout, order history.
* 💳 **Secure Payments**: Razorpay and PhonePe integrations.
* 📍 **Address Selection**: Google Maps picker for accurate delivery addresses.
* 🔔 **Push Notifications**: Firebase Cloud Messaging for promotions and order updates.
* 🌐 **Multiplatform**: Android, iOS, Web, macOS, Windows, Linux.

## Tech Stack

* **Framework**: Flutter 3.x
* **Language**: Dart
* **Authentication**: Custom OTP flow
* **Payments**: Razorpay, PhonePe SDKs
* **Maps**: Google Maps Flutter plugin
* **Notifications**: Firebase Cloud Messaging

## Prerequisites

* Flutter SDK ≥ 3.0.0
* Dart SDK
* Android Studio (for Android)
* Xcode (for iOS)
* Google Firebase project with FCM enabled
* Google Maps API key
* Razorpay & PhonePe merchant accounts

## Setup & Installation

1. **Clone the repo**

   ```bash
   git clone https://github.com/your-org/otto-mart.git
   cd otto-mart
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Platform setup**

   * **Android**: Place `google-services.json` in `android/app/`.
   * **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`.
   * **Web/Desktop**: Ensure web icons & manifests in `web/`.

## Configuration

Update `lib/utils/constants.dart` with:

```dart
const String API_BASE_URL = "https://api.otto-mart.com";
const String GOOGLE_MAPS_API_KEY = "YOUR_KEY_HERE";
```

Set up `firebase_options.dart` via FlutterFire CLI:

```bash
flutterfire configure
```

Add merchant credentials in secure storage or environment:

* `RAZORPAY_KEY`
* `PHONEPE_MERCHANT_ID` & `PHONEPE_SECRET`

## Project Structure

```
.
├── android/        # Android native files
├── ios/            # iOS native files
├── lib/            # Dart source code
│   ├── catalog/    # Product listing & categories
│   ├── cart/       # Cart & checkout flows
│   ├── home/       # Home screen and tabs
│   ├── item/       # Product detail & reviews
│   ├── login/      # OTP login screens & API
│   ├── payments/   # Razorpay & PhonePe handlers
│   ├── search/     # Search UI & logic
│   ├── setting/    # User profile & settings
│   └── utils/      # Constants, network, and helpers
├── assets/         # Images, icons, Lottie animations
├── web/            # Web deployment files
├── pubspec.yaml    # Flutter metadata & dependencies
└── README.md       # This file
```

## Usage

* **Run** on a connected device or simulator:

  ```bash
  flutter run
  ```
* **Hot reload**: Press `r` in terminal or use IDE shortcut.

## Payments

* **Razorpay**: `lib/payments/razorpay.dart` handles payment initiation and callbacks.
* **PhonePe**: `lib/payments/phonepe.dart` for init and verification.
* Ensure credentials are securely stored and not committed.

## Maps & Address

* Google Maps widget in `lib/cart/address/` for address selection.
* Autocomplete & reverse-geocoding via Google Maps Places API.

## Notifications

* FCM setup in `lib/utils/network/`.
* Handlers for foreground, background, and terminated states in `main.dart`.

## Testing

* **Unit & Widget**:

  ```bash
  flutter test
  ```

* **Integration** (requires device/emulator):

  ```bash
  flutter drive --target=test_driver/app.dart
  ```

## Deployment

* **Android**: `flutter build apk --release`
* **iOS**: `flutter build ios --release`
* **Web**: `flutter build web --release`
* **Desktop**: `flutter build macos/windows/linux`

Monitor via Firebase Analytics and Crashlytics; support 200+ active users in production.

## Contributing

1. Fork and clone
2. Create branch: `git checkout -b feature/xyz`
3. Commit: `git commit -m "Add xyz feature"`
4. Push: `git push origin feature/xyz`
5. Open a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.
