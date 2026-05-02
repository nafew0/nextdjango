# Quick Start Guide

Get your Django + Next.js SaaS starter up and running in minutes.

## Prerequisites

```bash
python3 --version   # 3.8+
node --version      # 18+
psql --version      # 12+
redis-server --version  # 6+ (for caching, Celery)
```

Install missing tools (macOS):
```bash
brew install python3 node postgresql@14 redis
brew services start postgresql@14
brew services start redis
```

## Option 1: Automated Setup (Recommended)

```bash
cd template
chmod +x setup.sh
./setup.sh
```

The script will prompt you for:
- Project name, database credentials
- Email SMTP settings (optional — defaults to console in dev)
- Stripe API keys (optional — skip for now, add later)
- bKash credentials (optional — skip for now, add later)

It will then:
- Create project directory and copy template files
- Set up PostgreSQL database
- Create Python virtual environment and install dependencies
- Run Django migrations
- Seed Free / Pro / Enterprise subscription plans
- Create superuser (optional)
- Install frontend npm packages
- Generate `start.sh`, `start_backend.sh`, `start_frontend.sh`

## Option 2: Manual Setup

```bash
# 1. Set up database
cd template && chmod +x setup_database.sh && ./setup_database.sh

# 2. Backend
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env — at minimum set DJANGO_SECRET_KEY, JWT_SIGNING_KEY, DB_NAME, DB_USER, DB_PASSWORD
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 8000

# 3. Frontend (new terminal)
cd frontend
npm install
cp .env.example .env
# Optional: change BACKEND_URL if Django is not on http://localhost:8000
npm run dev
```

## Start the App

```bash
./start.sh           # both servers
./start_backend.sh   # backend only  (port 8000)
./start_frontend.sh  # frontend only (port 3000)
```

## Access

| URL | What |
|-----|------|
| http://localhost:3000 | Frontend |
| http://localhost:8000/api | REST API |
| http://localhost:8000/admin | Django Admin |

## First Things to Test

1. **Register** → confirm auto-login works by default
2. **Login** → JWT issued, cookie set
3. **Pricing page** (`/pricing`) → plans displayed
4. **Admin panel** (`/admin`) → log in as staff/superuser, then review Authentication defaults for email verification and signup rate limits
5. **Profile** → update avatar, org, change password

## Production Note

For reliable signup and auth rate limiting in production, set `USE_REDIS=true` and back it with a shared Redis cache. If the app is behind a reverse proxy, also configure `TRUSTED_PROXY_IPS` so IP-based throttles see the real client IP instead of the proxy address.

## Configuring Payments

### Stripe
1. Create products & prices in Stripe Dashboard
2. Add `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET` to `backend/.env`
3. Add `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` to `frontend/.env`
4. Update `Plan.stripe_price_id_monthly` / `stripe_price_id_yearly` via Django admin
5. Set up webhook endpoint: `POST /api/payments/stripe/webhook/`

### bKash
1. Obtain bKash merchant credentials
2. Add `BKASH_APP_KEY`, `BKASH_APP_SECRET`, `BKASH_USERNAME`, `BKASH_PASSWORD` to `backend/.env`
3. Set `BKASH_BASE_URL` to production URL when going live
4. Update `Plan.bkash_price_monthly` / `bkash_price_yearly` via Django admin

## Customising Plan Limits

The `Plan.max_items` field is a generic limit. Rename it to fit your domain by:
1. Overriding `LicenseService.get_item_count()` in `subscriptions/services.py`
2. Calling `LicenseService.check_can_create_item(user)` before creating items

## Common Issues

**Port in use:**
```bash
lsof -ti:8000 | xargs kill -9
lsof -ti:3000 | xargs kill -9
```

**Redis not running:**
```bash
redis-server --daemonize yes
```

**Migration errors:**
```bash
cd backend && source venv/bin/activate
python manage.py showmigrations
python manage.py migrate --run-syncdb
```

**Rebuild dependencies:**
```bash
# Backend
rm -rf backend/venv && cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt

# Frontend
rm -rf frontend/node_modules frontend/package-lock.json && cd frontend && npm install
```

See [README.md](README.md) for full documentation.
