# FreshKart - Customer App

Mobile application for customers to browse groceries, book home services, and manage orders.

## Features

- **Grocery Shopping** - Browse products by category, search, add to cart, and checkout
- **Home Services** - Book plumbing, electrical, cleaning, and other services
- **Order Tracking** - Real-time delivery status with driver location
- **Scheduled Orders** - Place orders for future delivery
- **Digital Wallet** - Topup balance and pay from wallet
- **Loyalty Points** - Earn points on purchases, redeem for discounts
- **Coupons** - Apply discount codes at checkout
- **Referrals** - Share referral codes and earn rewards
- **In-App Chat** - Communicate with vendors and delivery agents
- **Push Notifications** - Order updates, promotions, and alerts
- **Multi-language** - English and Tamil support
- **Address Management** - Save multiple delivery addresses

## Project Structure

```
customerapp/lib/
├── core/
│   ├── api/              # REST API client (Dio)
│   ├── config/           # Supabase configuration
│   ├── location/         # Geolocation services
│   ├── models/           # Data models
│   ├── notifications/    # FCM push notification setup
│   ├── router/           # GoRouter navigation
│   ├── storage/          # SharedPreferences
│   ├── theme/            # Material Design theme
│   └── utils/            # Helpers (date, currency, validators)
└── features/
    ├── auth/             # Login, signup, OTP verification
    ├── splash/           # Splash screen
    ├── onboarding/       # First-time user walkthrough
    ├── home/             # Dashboard / main screen
    ├── grocery/          # Product catalog and search
    ├── cart/             # Shopping cart management
    ├── orders/           # Order history and tracking
    ├── services/         # Service browsing and booking
    ├── bookings/         # Service booking management
    ├── chat/             # Real-time messaging
    ├── wallet/           # Wallet balance and transactions
    ├── loyalty/          # Loyalty points dashboard
    ├── coupon/           # Coupon application
    ├── referral/         # Referral code sharing
    ├── profile/          # User profile and settings
    └── shared/           # Common widgets
```

## Tech Stack

- **Framework**: Flutter 3.10.4
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Supabase + REST API (Dio)
- **Payments**: Razorpay
- **Notifications**: Firebase Cloud Messaging
- **Location**: Geolocator

## Getting Started

```bash
cd customerapp
flutter pub get
flutter run
```

Ensure the backend API is running and Supabase is configured before launching.

## Configuration

The app connects to:
- **Supabase** for auth and real-time features (configured in `core/config/`)
- **Backend API** for business logic (configured in `core/api/`)
- **Firebase** for push notifications (configured via `google-services.json` / `GoogleService-Info.plist`)
