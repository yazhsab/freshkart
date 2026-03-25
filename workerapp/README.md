# FreshKart - Worker App

Mobile application for service professionals (plumbers, electricians, cleaners, etc.) to manage bookings and provide home services.

## Features

- **Booking Management** - View, accept, and manage service bookings
- **Job Tracking** - Track active jobs from start to completion
- **Availability Slots** - Set and manage available time slots for bookings
- **Schedule View** - Calendar view of upcoming bookings
- **Earnings Dashboard** - Track service earnings and payouts
- **In-App Chat** - Communicate with customers about service details
- **Push Notifications** - New booking alerts and reminders
- **Profile Management** - Update skills, service areas, and availability

## Project Structure

```
workerapp/lib/
├── core/
│   ├── api/              # REST API client
│   ├── config/           # Supabase configuration
│   ├── models/           # Data models
│   ├── notifications/    # FCM setup
│   ├── router/           # Navigation
│   ├── storage/          # Local storage
│   └── theme/            # App theme
└── features/
    ├── auth/             # Worker login
    ├── home/             # Available bookings
    ├── bookings/         # Booking details and management
    ├── job/              # Active job tracking
    ├── schedule/         # Availability slot management
    ├── earnings/         # Payment tracking
    ├── chat/             # Customer communication
    └── profile/          # Worker profile and settings
```

## Tech Stack

- **Framework**: Flutter 3.10.4
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Supabase + REST API (Dio)
- **Location**: Geolocator
- **Notifications**: Firebase Cloud Messaging

## Getting Started

```bash
cd workerapp
flutter pub get
flutter run
```

## Booking Workflow

1. Customer books a service for a specific date/time slot
2. Worker receives notification and views booking details
3. Worker accepts the booking and arrives at the scheduled time
4. Worker marks the job as started, then completed
5. Customer confirms completion and leaves a review
6. Earnings are credited to the worker's account
