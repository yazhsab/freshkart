# FreshKart - Native iOS Apps

Four standalone iOS apps built with Swift and SwiftUI.

## Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Package Manager**: Swift Package Manager
- **Networking**: URLSession with Actor-based APIClient
- **JSON**: Codable protocol with custom key decoding
- **Storage**: UserDefaults (custom LocalStorage)
- **Auth**: Firebase Auth + Google Sign-In
- **Push Notifications**: Firebase Cloud Messaging
- **Dependencies**: Google Sign-In 7.0.0, Firebase iOS SDK 10.0.0
- **Min iOS**: 17

## Apps

### Customer App (`customerapp/`)

Bundle ID: `com.freshkart.customer` | SwiftUI app

Full-featured grocery and services ordering app.

**Features:** Product browsing, search, cart, order tracking, service bookings, wallet, loyalty points, coupons, referrals, in-app chat, notifications

**Permissions:** Location (when in use + always), Camera, Photo library

**Localization:** English, Tamil

### Vendor App (`vendorapp/`)

Bundle ID: `com.freshkart.vendor` | SwiftUI app

Shop management for grocery vendors.

**Features:** Dashboard, order processing, inventory management, coupon management, earnings, chat, shop settings

**Permissions:** Location (when in use), Camera, Photo library

**Background Modes:** Remote notifications

### Driver App (`driverapp/`)

Bundle ID: `com.freshkart.delivery` | SwiftUI app

Delivery fulfillment with real-time tracking.

**Features:** Delivery dashboard, order acceptance, delivery tracking, earnings, history, customer chat

**Permissions:** Location (when in use + **background**), Camera, Photo library

**Background Modes:** Remote notifications, **Location updates**

### Worker App (`workerapp/`)

Bundle ID: `com.freshkart.worker` | SwiftUI app

Home service professional booking management.

**Features:** Booking management, job tracking, schedule/availability, earnings, customer chat

**Permissions:** Location (when in use), Camera, Photo library

**Background Modes:** Remote notifications

## Architecture

Each app follows a clean layered architecture:

```
FreshKart{Role}/
├── App/
│   ├── FreshKart{Role}App.swift    # @main entry point
│   ├── AppDelegate.swift            # Firebase + FCM setup
│   └── ContentView.swift            # Root navigation
├── Core/
│   ├── Network/
│   │   └── APIClient.swift          # Actor-based HTTP client
│   ├── Storage/
│   │   └── LocalStorage.swift       # UserDefaults wrapper
│   ├── Location/                    # CLLocationManager
│   └── Utils/                       # Extensions, helpers
├── Models/                          # Codable structs
├── Repositories/                    # Data access layer
├── ViewModels/                      # @Observable business logic
└── Views/                           # SwiftUI screens by feature
```

**Key design patterns:**
- Actor-based `APIClient` for thread-safe networking
- Automatic token refresh on 401 responses
- Repository pattern for data access
- `@StateObject` / `@EnvironmentObject` for state management

## Building

Open each app's Xcode project or use the Swift Package:

```bash
cd native/ios/customerapp
open FreshKartCustomer.xcodeproj

# Or build from command line
xcodebuild -scheme FreshKartCustomer -sdk iphonesimulator build
```

Requires Xcode 15+ with iOS 17 SDK.
