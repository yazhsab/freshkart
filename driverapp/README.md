# FreshKart - Driver App

Mobile application for delivery agents to manage and fulfill grocery delivery orders.

## Features

- **Available Orders** - View and accept nearby delivery requests
- **Active Deliveries** - Step-by-step delivery workflow (pickup, in-transit, delivered)
- **Route Navigation** - Navigate to pickup and drop-off locations
- **Earnings Dashboard** - Track daily/weekly/monthly earnings
- **Delivery History** - View completed deliveries and performance stats
- **In-App Chat** - Communicate with customers during delivery
- **Push Notifications** - New order alerts and delivery updates
- **Profile Management** - Update availability and vehicle details

## Project Structure

```
driverapp/lib/
├── core/
│   ├── api/              # REST API client
│   ├── config/           # Supabase configuration
│   ├── models/           # Data models
│   ├── notifications/    # FCM setup
│   ├── router/           # Navigation
│   ├── storage/          # Local storage
│   └── theme/            # App theme
└── features/
    ├── auth/             # Driver login
    ├── home/             # Available orders
    ├── delivery/         # Active delivery tracking
    ├── earnings/         # Revenue and analytics
    ├── history/          # Completed deliveries
    ├── chat/             # Customer communication
    └── profile/          # Driver profile and settings
```

## Tech Stack

- **Framework**: Flutter 3.10.4
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Supabase + REST API (Dio)
- **Location**: Geolocator (real-time tracking)
- **Notifications**: Firebase Cloud Messaging

## Getting Started

```bash
cd driverapp
flutter pub get
flutter run
```

## Delivery Workflow

1. Driver sees available orders on the home screen
2. Accepts an order and navigates to the vendor for pickup
3. Confirms pickup and begins delivery to the customer
4. Marks delivery as completed upon drop-off
5. Earnings are credited and visible in the dashboard
