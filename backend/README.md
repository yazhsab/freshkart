# FreshKart - Backend API

Node.js/Express REST API powering all FreshKart mobile apps and the admin panel.

## Tech Stack

- **Runtime**: Node.js >= 18
- **Framework**: Express 4.18
- **Database**: Supabase (PostgreSQL)
- **Cache/Queue**: Upstash Redis + BullMQ
- **Payments**: Razorpay, PhonePe
- **Notifications**: Firebase Cloud Messaging
- **SMS/OTP**: MSG91
- **File Storage**: Cloudflare R2 (S3-compatible)
- **Maps**: Ola Maps API
- **Validation**: Joi
- **Logging**: Winston with daily rotate
- **Deployment**: Railway

## Project Structure

```
backend/src/
├── server.js              # Entry point
├── config/                # Service configurations
│   ├── firebase.config.js
│   ├── supabase.config.js
│   ├── razorpay.config.js
│   ├── redis.config.js
│   └── r2.config.js
├── controllers/           # Business logic (19 controllers)
├── routes/                # API route definitions (20 route files)
├── services/              # External service integrations (15 services)
├── middleware/
│   ├── auth.js            # JWT verification
│   ├── adminAuth.js       # Admin role validation
│   ├── rateLimiter.js     # Rate limiting
│   ├── errorHandler.js    # Global error handler
│   ├── upload.js          # File upload validation
│   └── validateRequest.js # Request schema validation
├── validators/            # Joi validation schemas
├── queues/                # BullMQ job queues
│   ├── notification.queue.js
│   ├── order.queue.js
│   └── booking.queue.js
├── crons/                 # Scheduled jobs
│   ├── auto.confirm.cron.js      # Auto-accept orders after 60s
│   ├── slot.cleanup.cron.js      # Remove expired booking slots
│   ├── payout.reminder.cron.js   # Notify pending payouts
│   └── scheduled.order.cron.js   # Process scheduled orders
└── utils/                 # Helpers and logging
```

## API Routes

| Route | Description |
|-------|-------------|
| `/auth` | Login, signup, JWT token management |
| `/products` | Product CRUD and search |
| `/categories` | Category management |
| `/orders` | Order lifecycle (create, confirm, deliver, cancel) |
| `/bookings` | Service booking management |
| `/payments` | Payment processing and webhooks |
| `/delivery` | Delivery agent assignment and tracking |
| `/workers` | Worker management and availability |
| `/vendors` | Vendor onboarding and shop details |
| `/reviews` | Ratings and reviews |
| `/wallet` | Digital wallet topup and debit |
| `/loyalty` | Loyalty points earn/redeem |
| `/coupons` | Coupon CRUD and validation |
| `/referral` | Referral code generation and tracking |
| `/chat` | Real-time messaging |
| `/admin` | Admin operations |
| `/notifications` | Push notification management |
| `/webhooks` | Payment and SMS callback handlers |
| `/health` | Health check endpoint |

## Getting Started

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Fill in all required values in `.env`:

| Variable | Service |
|----------|---------|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` | Supabase |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Razorpay |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Firebase (FCM) |
| `MSG91_AUTH_KEY`, `MSG91_OTP_TEMPLATE_ID` | MSG91 (SMS) |
| `OLA_MAPS_API_KEY` | Ola Maps |
| `CLOUDFLARE_R2_*` | Cloudflare R2 (file storage) |
| `UPSTASH_REDIS_URL`, `UPSTASH_REDIS_TOKEN` | Redis |

See [`.env.example`](.env.example) for the full list.

### 3. Run

```bash
# Development (with hot reload)
npm run dev

# Production
npm start
```

The server starts on `http://localhost:3000` by default.

### 4. Verify

```bash
curl http://localhost:3000/health
```

## Background Jobs

**BullMQ Queues** (requires Redis):
- `notification.queue` - Async push notification delivery
- `order.queue` - Order processing pipeline
- `booking.queue` - Booking lifecycle management

**Cron Jobs** (node-cron):
- Auto-confirm vendor orders after 60 seconds of inactivity
- Clean up expired worker availability slots
- Send payout reminders for pending settlements
- Process scheduled orders at their delivery time

## Deployment

Deployed on **Railway** using the nixpacks builder.

```toml
# railway.toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "node src/server.js"
healthcheckPath = "/health"
healthcheckTimeout = 300
```

Firebase service accounts can be provided either as a JSON file or as a base64-encoded environment variable (`FIREBASE_SERVICE_ACCOUNT_BASE64`).

## Testing

```bash
npm test
```

Uses Jest and Supertest for API testing.
