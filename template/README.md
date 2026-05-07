# Django + Next.js Project Template with Authentication

A production-ready template for building full-stack web applications with Django REST Framework and Next.js, featuring a complete authentication system.

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Manual Setup](#manual-setup)
- [Environment Configuration](#environment-configuration)
- [API Endpoints](#api-endpoints)
- [Frontend Routes](#frontend-routes)
- [Common Pitfalls](#common-pitfalls)
- [Manual Changes Needed](#manual-changes-needed)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

---

## Features

### Backend (Django)
- Django 4.2 with Django REST Framework
- JWT-based authentication with token refresh
- Token blacklisting on logout
- Custom User model with UUID primary key
- PostgreSQL database
- Redis for caching and WebSocket support
- Django Channels for real-time features
- CORS configured for frontend
- Comprehensive authentication endpoints
- Admin interface
- Automated testing setup

### Frontend (Next.js)
- Next.js 16 App Router with React 19
- **shadcn/ui** component library (Radix UI + Tailwind CSS)
- File-based routing under `src/app/`
- Tailwind CSS for styling
- Axios with automatic token refresh
- TanStack Query for server state
- Context API for app-wide state
- Protected routes
- Beautiful, accessible UI components
- Dark mode ready
- Login/Register/Profile pages
- Responsive design
- Lucide React icons
- Environment-based configuration

---

## Project Structure

```
project-name/
├── backend/                    # Django backend
│   ├── project_name/          # Django project settings
│   │   ├── __init__.py
│   │   ├── settings.py        # Main settings file
│   │   ├── urls.py            # Root URL configuration
│   │   ├── asgi.py            # ASGI configuration
│   │   └── wsgi.py            # WSGI configuration
│   ├── accounts/              # Authentication app
│   │   ├── migrations/        # Database migrations
│   │   ├── __init__.py
│   │   ├── admin.py           # Admin configuration
│   │   ├── apps.py            # App configuration
│   │   ├── models.py          # User model
│   │   ├── serializers.py     # API serializers
│   │   ├── views.py           # API views
│   │   ├── urls.py            # App URLs
│   │   └── tests.py           # Unit tests
│   ├── venv/                  # Python virtual environment
│   ├── manage.py              # Django management script
│   ├── requirements.txt       # Python dependencies
│   ├── .env                   # Environment variables (not in git)
│   ├── .env.example           # Example environment file
│   └── .gitignore             # Git ignore rules
│
├── frontend/                   # Next.js frontend
│   ├── public/                # Static files
│   ├── src/app/               # App Router entrypoints and layouts
│   ├── src/
│   │   ├── components/        # Client components
│   │   │   ├── Navbar.tsx     # Navigation bar
│   │   │   └── ProtectedRoute.tsx  # Route protection
│   │   ├── contexts/          # React contexts
│   │   │   └── AuthContext.tsx     # Authentication context
│   │   ├── views/             # Route view components
│   │   │   ├── Home.tsx       # Home page
│   │   │   ├── Login.tsx      # Login page
│   │   │   ├── Register.tsx   # Registration page
│   │   │   ├── Dashboard.tsx  # User dashboard
│   │   │   └── Profile.tsx    # User profile
│   │   ├── services/          # API services
│   │   │   └── api.ts         # Axios configuration
│   │   ├── hooks/             # Custom hooks (add your own)
│   │   ├── utils/             # Utility functions (add your own)
│   │   └── lib/               # Shared helpers and theme utilities
│   ├── package.json           # NPM dependencies
│   ├── next.config.ts         # Next.js rewrites and config
│   ├── tsconfig.json          # TypeScript configuration
│   ├── eslint.config.mjs      # ESLint configuration
│   ├── tailwind.config.js     # Tailwind configuration
│   ├── postcss.config.mjs     # PostCSS configuration
│   ├── .env                   # Environment variables (not in git)
│   ├── .env.example           # Example environment file
│   └── .gitignore             # Git ignore rules
│
├── setup.sh                   # Automated setup script (auto-detects platform)
├── setup_linux.sh             # Linux / Ubuntu setup wrapper
├── setup_windows.sh           # Windows Git Bash setup wrapper
├── setup_database.sh          # Database setup script
├── start_backend.sh           # Start Django server
├── start_frontend.sh          # Start Next.js dev server
├── start.sh                   # Start both servers
└── README.md                  # This file
```

---

## Prerequisites

Before you begin, ensure you have the following installed on your machine:

1. **Python 3.8+**
   ```bash
   python3 --version
   ```

2. **Node.js 18+ and npm**
   ```bash
   node --version
   npm --version
   ```

3. **PostgreSQL 12+**
   ```bash
   brew install postgresql@14
   brew services start postgresql@14
   ```

4. **Redis** (optional, for WebSocket support)
   ```bash
   brew install redis
   brew services start redis
   ```

5. **Git**
   ```bash
   git --version
   ```

---

## Quick Start

The easiest way to set up a new project is using the automated setup script:

```bash
cd template
chmod +x setup.sh
./setup.sh
```

Platform-specific wrappers are also available:

```bash
# Linux / Ubuntu
chmod +x setup_linux.sh
./setup_linux.sh

# Windows (Git Bash)
./setup_windows.sh
```

The script will:
1. Prompt you for project configuration (name, database, etc.)
2. Create the project directory
3. Copy and configure all template files
4. Set up the PostgreSQL database
5. Create Python virtual environment
6. Install all dependencies
7. Run database migrations
8. Create a superuser (optional)
9. Create start scripts

After setup completes:

```bash
cd your-project-name
./start.sh  # Starts both backend and frontend
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/api
- Django Admin: http://localhost:8000/admin

---

## Manual Setup

If you prefer to set up the project manually:

### 1. Database Setup

```bash
cd template
chmod +x setup_database.sh
./setup_database.sh
```

Or manually:

```bash
# Create database
psql -U postgres
CREATE DATABASE your_db_name;
\q
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your configuration

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Start server
python manage.py runserver 8000
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env if needed (the default `/api` value works for local dev)

# Start development server
npm run dev
```

---

## Environment Configuration

### Backend (.env)

```env
# Django Settings
DJANGO_SECRET_KEY=__REQUIRED__
JWT_SIGNING_KEY=__REQUIRED__
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
TRUST_X_FORWARDED_PROTO=False

# Database
DB_NAME=your_db_name
DB_USER=__REQUIRED__
DB_PASSWORD=__REQUIRED__
DB_HOST=localhost
DB_PORT=5432

# Redis
USE_REDIS=False
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
# TRUSTED_PROXY_IPS=127.0.0.1
```

For production, set `USE_REDIS=true` and point it at a shared Redis instance. Django `LocMemCache` is not enough for reliable API rate limiting when you run multiple app workers, and `TRUSTED_PROXY_IPS` must be set correctly if your app sits behind Nginx, Traefik, Cloudflare, or another reverse proxy.

### Frontend (.env)

```env
BACKEND_URL=http://localhost:8000
NEXT_PUBLIC_API_URL=/api
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
NEXT_PUBLIC_DJANGO_ADMIN_URL=http://localhost:8000/admin
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/auth/register/captcha/` | Issue the signup CAPTCHA challenge and signed registration token | No |
| POST | `/api/auth/register/` | Register new user | No |
| POST | `/api/auth/login/` | Login user | No |
| POST | `/api/auth/logout/` | Logout user | Yes |
| POST | `/api/auth/token/refresh/` | Refresh access token | No |
| GET | `/api/auth/user/` | Get current user | Yes |
| PATCH | `/api/auth/user/update/` | Update user profile | Yes |
| POST | `/api/auth/user/change-password/` | Change password | Yes |
| DELETE | `/api/auth/user/delete/` | Delete account | Yes |

### Request/Response Examples

**Register:**
```json
POST /api/auth/register/
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "password2": "SecurePass123!",
  "first_name": "John",
  "last_name": "Doe",
  "registration_token": "signed-token-from-/api/auth/register/captcha/",
  "captcha_id": "captcha-id-when-enabled",
  "captcha_answer": "12",
  "company_website": ""
}

Response:
{
  "user": {
    "id": "uuid",
    "username": "john_doe",
    "email": "john@example.com",
    ...
  },
  "access_token": "access_token",
  "message": "User registered successfully."
}
```

Before posting registration, fetch `/api/auth/register/captcha/`. It always returns a signed `registration_token`, and when signup CAPTCHA is enabled it also returns `captcha_id` and a simple arithmetic prompt.

New installs start with email verification turned off, so successful registration returns an access token immediately. An admin can later enable email verification and tune the fixed-window signup limits from the admin settings screen without editing environment variables.

**Login:**
```json
POST /api/auth/login/
{
  "username": "john_doe",
  "password": "SecurePass123!"
}

Response: Same as register
```

---

## Frontend Routes

| Route | Component | Protected | Description |
|-------|-----------|-----------|-------------|
| `/` | `src/app/page.tsx` → `Home` | No | Landing page |
| `/login` | `src/app/login/page.tsx` → `Login` | No | Login page |
| `/register` | `src/app/register/page.tsx` → `Register` | No | Registration page |
| `/verify-email` | `src/app/verify-email/page.tsx` → `VerifyEmail` | No | Email verification flow |
| `/pricing` | `src/app/pricing/page.tsx` → `Pricing` | No | Plan selection and checkout entry |
| `/dashboard` | `src/app/dashboard/page.tsx` → `Dashboard` | Yes | User dashboard |
| `/profile` | `src/app/profile/page.tsx` → `Profile` | Yes | User profile page |
| `/admin/*` | `src/app/admin/**/page.tsx` | Staff | Admin dashboard, users, payments, settings |

---

## Common Pitfalls

### 1. Port Conflicts

**Problem:** Ports 8000 or 3000 are already in use.

**Solution:**
```bash
# Find and kill process on port 8000
lsof -ti:8000 | xargs kill -9

# Find and kill process on port 3000
lsof -ti:3000 | xargs kill -9
```

Or change ports in:
- Backend: `python manage.py runserver <new_port>`
- Frontend: `npm run dev -- --port 3001`

### 2. PostgreSQL Not Running

**Problem:** Database connection errors.

**Solution:**
```bash
# Check if PostgreSQL is running
pg_isready

# Start PostgreSQL
brew services start postgresql@14

# Or restart
brew services restart postgresql@14
```

### 3. Virtual Environment Issues

**Problem:** Python packages not found or version conflicts.

**Solution:**
```bash
# Delete and recreate venv
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. CORS Errors

**Problem:** Frontend can't access backend API.

**Solution:** In local development, keep `frontend/.env` on `NEXT_PUBLIC_API_URL=/api` so the browser talks to Next.js on `localhost:3000` and Next rewrites requests to Django. If you point the browser directly at `http://localhost:8000/api`, then also make sure `APP_ORIGIN`, `PUBLIC_APP_URL`, and `CORS_ALLOWED_ORIGINS` in `backend/.env` / `settings.py` match your frontend origin.

### 5. Token Expiration

**Problem:** Users getting logged out frequently.

**Solution:** Adjust token lifetime in `backend/settings.py`:
```python
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),  # Increase this
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),  # Or this
}
```

### 6. Static Files Not Loading

**Problem:** CSS/JS not loading in production.

**Solution:**
```bash
python manage.py collectstatic
```

### 7. Migration Conflicts

**Problem:** Database migration errors.

**Solution:**
```bash
# Reset migrations (WARNING: This deletes data)
python manage.py migrate accounts zero
rm accounts/migrations/0*.py
python manage.py makemigrations
python manage.py migrate
```

### 8. Node Modules Issues

**Problem:** Frontend dependencies not working.

**Solution:**
```bash
rm -rf node_modules package-lock.json
npm install
```

---

## Manual Changes Needed

After setting up the project, you may want to customize the following:

### 1. Project Branding

**Files to update:**
- `frontend/src/components/Navbar.tsx` - Update project name and navigation labels
- `frontend/src/app/layout.tsx` - Update metadata title and description
- `frontend/public/branding/` - Replace the bundled fallback branding images/logo

You can also upload a runtime logo, favicon, login banner, and registration banner from the admin settings screen after setup. Those uploads override the bundled files without rebuilding the frontend. Uploaded assets are validated against pixel caps before saving.

### 2. Django Secret Key

For production, generate new values for both Django signing secrets:
```python
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```

Update in `backend/.env`:
```env
DJANGO_SECRET_KEY=your-new-secret-key-here
JWT_SIGNING_KEY=your-separate-jwt-signing-key
```

### 3. Database Configuration

Update `backend/.env` with your production database:
```env
DB_NAME=production_db
DB_USER=production_user
DB_PASSWORD=strong_password
DB_HOST=your_db_host
```

### 4. CORS Settings for Production

Update `backend/settings.py`:
```python
CORS_ALLOWED_ORIGINS = [
    "https://yourdomain.com",
]
```

### 5. Frontend API URL

Update `frontend/.env`:
```env
BACKEND_URL=https://api.yourdomain.com
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api
```

For local development, keep `BACKEND_URL=http://localhost:8000` and `NEXT_PUBLIC_API_URL=/api` so Next.js proxies requests to Django and you avoid browser CORS issues.

### 6. Add Your App

Create new Django apps:
```bash
cd backend
python manage.py startapp your_app_name
```

Add to `INSTALLED_APPS` in `settings.py`

### 7. Customize User Model

If you need additional fields in the User model:

**Edit:** `backend/accounts/models.py`
```python
class User(AbstractUser):
    # Add your fields here
    phone_number = models.CharField(max_length=20, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
```

**Then run:**
```bash
python manage.py makemigrations
python manage.py migrate
```

### 8. Email Configuration (Optional)

For password reset and email features, add to `backend/.env`:
```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### 9. Add More Frontend Pages

Create or update a view in `frontend/src/views/`, then wire a route entrypoint in `frontend/src/app/<route>/page.tsx`.

### 10. Customize Styling

Edit `frontend/tailwind.config.js` to match your brand colors:
```javascript
theme: {
  extend: {
    colors: {
      primary: '#your-color',
      secondary: '#your-color',
    },
  },
},
```

Most visual tokens also live in `frontend/src/app/globals.css` and `frontend/src/lib/siteTheme.ts`.

---

## Development Workflow

### Adding a New Feature

1. **Backend:**
   ```bash
   cd backend
   source venv/bin/activate

   # Create models
   # Edit models.py
   python manage.py makemigrations
   python manage.py migrate

   # Create serializers, views, URLs
   # Test in Django admin or API browser
   ```

2. **Frontend:**
   ```bash
   cd frontend

   # Create components/views
   # Add or update a page entry under src/app/
   # Create API service functions
   npm run dev
   ```

### Database Changes

```bash
# Make model changes
python manage.py makemigrations
python manage.py migrate

# To rollback
python manage.py migrate app_name 0001  # Roll back to migration 0001
```

### Running Tests

**Backend:**
```bash
cd backend
source venv/bin/activate
pytest
# Or
python manage.py test
```

**Frontend:**
```bash
cd frontend
npm run lint
npx tsc --noEmit
```

---

## Testing

### Backend Testing

Create tests in `accounts/tests.py`:
```python
from django.test import TestCase
from rest_framework.test import APIClient

class MyTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_something(self):
        # Your test code
        pass
```

Run tests:
```bash
python manage.py test
# Or with pytest
pytest
```

### Frontend Testing

The template currently ships with linting and TypeScript checks, not a bundled frontend test runner. The default verification commands are:

```bash
cd frontend
npm run lint
npx tsc --noEmit
```

If you want component or end-to-end tests, add your preferred stack on top of the template, such as React Testing Library, Vitest, or Playwright.

---

## Deployment

### Backend Deployment (Production)

1. **Update settings.py:**
   ```python
   DEBUG = False
   ALLOWED_HOSTS = ['your-domain.com']
   ```

2. **Collect static files:**
   ```bash
   python manage.py collectstatic
   ```

3. **Use production server:**
   ```bash
   pip install gunicorn
   gunicorn project_name.wsgi:application
   ```

### Frontend Deployment

1. **Build for production:**
   ```bash
   npm run build
   ```

2. **Run the production server** locally with:
   ```bash
   npm run start
   ```

3. **Deploy the Next.js app** to a platform that supports Node-based Next.js runtimes, such as Vercel, Railway, or a container/VM setup.

### Recommended Hosting

- **Backend:** Heroku, Railway, DigitalOcean, AWS
- **Frontend:** Vercel, Railway, Docker/VM hosting for Next.js
- **Database:** AWS RDS, ElephantSQL, DigitalOcean Managed Databases

---

## Troubleshooting

### Backend won't start

```bash
# Check Python version
python3 --version

# Activate venv
source venv/bin/activate

# Check for errors
python manage.py check

# View detailed errors
python manage.py runserver
```

### Frontend won't start

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node version
node --version

# Try alternative port
npm run dev -- --port 3001
```

### Database connection failed

```bash
# Check PostgreSQL
pg_isready

# Check credentials in .env
cat backend/.env

# Test connection
psql -U your_user -d your_db_name
```

### Token issues

Check:
1. The access token is being refreshed successfully from `/api/auth/token/refresh/`
2. The refresh cookie is present in the browser
3. The API interceptor is adding the `Authorization` header after login
4. Token lifetime settings in `SIMPLE_JWT` match your expectations

### Build errors

```bash
# Backend
pip install --upgrade pip
pip install -r requirements.txt

# Frontend
npm install
npm run build
```

---

## Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Next.js Documentation](https://nextjs.org/docs)
- [React Documentation](https://react.dev/)
- [**shadcn/ui Documentation**](https://ui.shadcn.com/) - See [SHADCN_UI_GUIDE.md](SHADCN_UI_GUIDE.md) for detailed usage
- [Radix UI](https://www.radix-ui.com/) - Accessible component primitives
- [Lucide Icons](https://lucide.dev/) - Beautiful icon library
- [Tailwind CSS](https://tailwindcss.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## Support

For issues related to:
- **Template bugs:** Create an issue in the template repository
- **Django/Next.js general questions:** Check official documentation
- **Database issues:** Check PostgreSQL documentation

---

## License

This template is provided as-is for your use. Modify as needed for your projects.

---

## Contributing

This template is based on the AniFight project. Feel free to customize and improve for your needs.

---

Happy Coding! 🚀
