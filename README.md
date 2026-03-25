# FreshKart

A full-stack dual-vertical marketplace platform for **grocery delivery** and **blue-collar home services**, built with Flutter and Node.js. Designed for regional markets in Tamil Nadu, India.

## Architecture

```
FreshKart/
├── customerapp/       # Customer mobile app (Flutter)
├── vendorapp/         # Vendor/shop owner app (Flutter)
├── driverapp/         # Delivery agent app (Flutter)
├── workerapp/         # Service professional app (Flutter)
├── native/
│   ├── android/       # Native Android apps (Kotlin + Jetpack Compose)
│   └── ios/           # Native iOS apps (Swift + SwiftUI)
├── lib/               # Shared code & Flutter web admin panel
├── backend/           # Node.js/Express REST API
└── supabase_schema.sql  # Database schema (PostgreSQL)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile Apps (Flutter) | Flutter 3.10.4, Riverpod, GoRouter |
| Mobile Apps (Native Android) | Kotlin 1.9.22, Jetpack Compose, Hilt, Retrofit |
| Mobile Apps (Native iOS) | Swift 5.9+, SwiftUI, URLSession |
| Admin Panel | Flutter Web |
| Backend API | Node.js, Express 4.18 |
| Database | Supabase (PostgreSQL) with Row-Level Security |
| File Storage | Cloudflare R2 |
| Cache/Queue | Upstash Redis, BullMQ |
| Payments | Razorpay, PhonePe |
| Auth/OTP | Supabase Auth, MSG91 |
| Push Notifications | Firebase Cloud Messaging |
| Maps | Ola Maps API |
| Deployment | Railway (backend), Vercel (admin) |

## Features

### Grocery Vertical
- Product catalog with categories and Tamil translations
- Real-time inventory management by vendors
- Shopping cart, instant & scheduled orders
- Live delivery tracking with driver assignment
- Delivery fee calculation

### Services Vertical
- Service categories (plumbing, electrical, cleaning, etc.)
- Worker availability slot management
- Date/time-based booking system

### Monetization
- Razorpay payment processing
- Digital wallet (topup & debit)
- Loyalty points program
- Coupon/discount system
- Referral rewards (configurable amounts)
- Commission-based payouts (Grocery: 10%, Services: 20%)

### Platform
- Geolocation-based zone filtering (Tamil Nadu districts)
- Real-time chat via Supabase Realtime
- Push notifications (FCM)
- SMS/OTP authentication
- Ratings & reviews
- Multi-language support (English & Tamil)

## Apps Overview

| App | Description | README |
|-----|-------------|--------|
| **Customer App** | Browse groceries & services, place orders, track deliveries | [customerapp/README.md](customerapp/README.md) |
| **Vendor App** | Manage shop inventory, process orders, track earnings | [vendorapp/README.md](vendorapp/README.md) |
| **Driver App** | Accept deliveries, navigate routes, manage earnings | [driverapp/README.md](driverapp/README.md) |
| **Worker App** | Manage service bookings, set availability, track jobs | [workerapp/README.md](workerapp/README.md) |
| **Backend API** | REST API powering all apps | [backend/README.md](backend/README.md) |
| **Admin Panel** | Platform management via Flutter Web | `lib/features/admin/` |
| **Native Android** | Kotlin + Jetpack Compose versions of all 4 apps | [native/android/README.md](native/android/README.md) |
| **Native iOS** | Swift + SwiftUI versions of all 4 apps | [native/ios/README.md](native/ios/README.md) |

## Prerequisites

- Flutter SDK >= 3.10.4 (for Flutter apps)
- Android Studio Hedgehog+ with Kotlin plugin (for native Android)
- Xcode 15+ with iOS 17 SDK (for native iOS)
- Node.js >= 18
- Supabase project
- Firebase project (for FCM)
- Razorpay account
- MSG91 account (for OTP)

## Quick Start

### 1. Database Setup

Apply the schema to your Supabase project:

```bash
# Import via Supabase dashboard SQL editor or CLI
psql -h YOUR_SUPABASE_HOST -U postgres -d postgres -f supabase_schema.sql
```

### 2. Backend

```bash
cd backend
cp .env.example .env
# Fill in all environment variables in .env
npm install
npm run dev
```

### 3. Flutter Apps

Each app can be run independently:

```bash
cd customerapp   # or vendorapp, driverapp, workerapp
flutter pub get
flutter run
```

For the admin panel (Flutter Web):

```bash
flutter pub get
flutter run -d chrome
```

### 4. Native Apps (Optional)

Native Android and iOS apps are in the `native/` directory. See [native/README.md](native/README.md) for build instructions.

## Environment Variables

See [`backend/.env.example`](backend/.env.example) for the full list of required environment variables including keys for Supabase, Razorpay, Firebase, MSG91, Ola Maps, Cloudflare R2, and Redis.

## Database

The full PostgreSQL schema is in `supabase_schema.sql` with 35+ tables covering:

- User profiles & addresses
- Vendors, products, categories
- Orders & order items
- Workers, slots, bookings
- Payments & payouts
- Wallets, loyalty, coupons, referrals
- Chat rooms & messages
- Zones & platform configuration
- 18+ performance indexes

## License

Proprietary. All rights reserved.
