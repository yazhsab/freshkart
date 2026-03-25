# FreshKart - Native Android Apps

Four standalone Android apps built with Kotlin and Jetpack Compose.

## Tech Stack

- **Language**: Kotlin 1.9.22
- **UI**: Jetpack Compose (BOM 2024.01.00)
- **DI**: Hilt 2.50
- **Networking**: Retrofit 2.9.0 + OkHttp 4.12.0
- **JSON**: Moshi 1.15.0
- **Images**: Coil 2.5.0
- **Storage**: DataStore Preferences 1.0.0
- **Navigation**: Jetpack Navigation Compose 2.7.6
- **Firebase**: FCM, Analytics, Auth
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)

## Apps

### Customer App (`customerapp/`)

Package: `com.freshkart.freshkart` | 144 Kotlin files

Full-featured grocery and services ordering app.

**Features:** Product browsing, search, cart, order tracking, service bookings, wallet, loyalty points, coupons, referrals, in-app chat, push notifications

**Permissions:** Location (foreground), Camera, Media access, Notifications

**API Base URL:** `https://freshkart-backend-vqp3.onrender.com/api/v1/`

### Vendor App (`vendorapp/`)

Package: `com.freshkart.vendor` | 70 Kotlin files

Shop management for grocery vendors.

**Features:** Dashboard, order processing, inventory management, coupon management, earnings tracking, chat, shop settings

**Permissions:** Camera, Media access, Notifications (no location)

### Driver App (`driverapp/`)

Package: `com.freshkart.delivery` | 45 Kotlin files

Delivery fulfillment with real-time tracking.

**Features:** Order acceptance, delivery tracking, route navigation, earnings, delivery history, customer chat

**Permissions:** Fine + Coarse location, **Background location**, Foreground service, Camera, Phone calls, Notifications

### Worker App (`workerapp/`)

Package: `com.freshkart.worker` | 43 Kotlin files

Home service professional booking management.

**Features:** Booking management, job tracking, schedule/availability, earnings, customer chat

**Permissions:** Fine + Coarse location, Camera, Notifications

## Architecture

Each app follows a consistent layered architecture:

```
app/src/main/java/com/freshkart/{role}/
├── FreshKartApp.kt           # Application class (Hilt entry point)
├── MainActivity.kt           # Single-activity Compose host
├── data/
│   ├── api/                  # Retrofit API interface + interceptors
│   ├── models/               # Moshi data classes
│   └── repository/           # Data access layer
├── di/                       # Hilt modules
├── ui/
│   ├── screens/              # Composable screens by feature
│   ├── components/           # Reusable UI components
│   ├── navigation/           # Navigation graph
│   └── theme/                # Material theme
└── viewmodels/               # Business logic + state
```

## Building

```bash
cd native/android

# Build specific app
./gradlew :customerapp:assembleDebug
./gradlew :vendorapp:assembleDebug
./gradlew :driverapp:assembleDebug
./gradlew :workerapp:assembleDebug

# Install on connected device
./gradlew :customerapp:installDebug
```

Requires Android Studio Hedgehog or later with Kotlin and Compose plugins.
