# FreshKart - Vendor App

Mobile application for grocery shop owners to manage their inventory, process customer orders, and track earnings.

## Features

- **Dashboard** - Sales overview, pending orders, and key metrics
- **Inventory Management** - Add, edit, and manage product listings with images
- **Order Processing** - Accept/reject orders, update order status
- **Coupon Management** - Create and manage discount codes for the shop
- **Earnings Tracking** - Revenue analytics with commission breakdown
- **Shop Settings** - Update shop details, operating hours, and delivery zones
- **In-App Chat** - Communicate with customers about their orders
- **Push Notifications** - Alerts for new orders and important updates

## Project Structure

```
vendorapp/lib/
├── core/
│   ├── api/              # REST API client
│   ├── config/           # Supabase configuration
│   ├── models/           # Data models
│   ├── notifications/    # FCM setup
│   ├── router/           # Navigation
│   ├── storage/          # Local storage
│   └── theme/            # App theme
└── features/
    ├── auth/             # Vendor login
    ├── dashboard/        # Sales overview
    ├── inventory/        # Product management
    ├── orders/           # Order processing
    ├── coupons/          # Discount management
    ├── earnings/         # Revenue tracking
    ├── chat/             # Customer communication
    └── shop/             # Shop settings and profile
```

## Tech Stack

- **Framework**: Flutter 3.10.4
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Supabase + REST API (Dio)
- **Notifications**: Firebase Cloud Messaging
- **Image Upload**: Image Picker + Cloudflare R2

## Getting Started

```bash
cd vendorapp
flutter pub get
flutter run
```

## Vendor Onboarding

Vendors must be approved by an admin before they can start selling. The onboarding flow includes:
1. Phone number verification via OTP
2. Shop details submission (name, address, FSSAI/GSTIN)
3. Document upload for verification
4. Admin approval
