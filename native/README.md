# FreshKart - Native Apps

Standalone native Android and iOS implementations of all four FreshKart apps. These are **not** Flutter platform channels — they are fully independent native apps built in parallel with the Flutter versions.

## Why Native?

The project maintains both Flutter and native implementations:
- **Flutter apps** (`customerapp/`, `vendorapp/`, `driverapp/`, `workerapp/`) for rapid cross-platform development
- **Native apps** (`native/android/`, `native/ios/`) for platform-specific optimizations and native performance

## Structure

```
native/
├── android/                  # Kotlin + Jetpack Compose
│   ├── customerapp/          # Customer shopping app
│   ├── vendorapp/            # Vendor shop management
│   ├── driverapp/            # Delivery agent app
│   └── workerapp/            # Service professional app
└── ios/                      # Swift + SwiftUI
    ├── customerapp/          # Customer shopping app
    ├── vendorapp/            # Vendor shop management
    ├── driverapp/            # Delivery agent app
    └── workerapp/            # Service professional app
```

## Tech Stack

| Platform | Language | UI Framework | DI | Networking | Min Version |
|----------|----------|-------------|-----|------------|-------------|
| Android | Kotlin 1.9.22 | Jetpack Compose 2024.01 | Hilt 2.50 | Retrofit 2.9 + OkHttp | API 26 (Android 8.0) |
| iOS | Swift 5.9+ | SwiftUI | - | URLSession (Actor-based) | iOS 17 |

## Shared Dependencies

**Android:**
- Hilt for dependency injection
- Retrofit + OkHttp for HTTP
- Moshi for JSON serialization
- Coil for image loading
- DataStore for local persistence
- Firebase (FCM, Analytics, Auth)
- Jetpack Navigation Compose

**iOS:**
- Swift Package Manager
- Google Sign-In 7.0.0
- Firebase iOS SDK 10.0.0
- Codable protocol for JSON
- UserDefaults for local storage

## Apps

| App | Android Package | iOS Bundle ID | Key Difference |
|-----|----------------|---------------|----------------|
| Customer | `com.freshkart.freshkart` | `com.freshkart.customer` | Full shopping + services |
| Vendor | `com.freshkart.vendor` | `com.freshkart.vendor` | No location needed |
| Driver | `com.freshkart.delivery` | `com.freshkart.delivery` | Background location tracking |
| Worker | `com.freshkart.worker` | `com.freshkart.worker` | Slot/schedule management |

See [android/README.md](android/README.md) and [ios/README.md](ios/README.md) for platform-specific details.
