#!/bin/bash

# Django + Next.js Project Setup Script
# This script sets up a new Django + Next.js project with authentication
# Based on template from AniFight project

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Django + Next.js SaaS Starter Setup                 ║${NC}"
echo -e "${BLUE}║   Auth · Subscriptions · Payments · Admin Panel       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

escape_sed_replacement() {
    printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

# Check if required commands are available
check_requirements() {
    print_info "Checking system requirements..."

    command -v python3 >/dev/null 2>&1 || { print_error "Python3 is required but not installed. Aborting."; exit 1; }
    command -v npm >/dev/null 2>&1 || { print_error "Node.js/npm is required but not installed. Aborting."; exit 1; }
    command -v psql >/dev/null 2>&1 || { print_error "PostgreSQL is required but not installed. Aborting."; exit 1; }

    print_success "All required commands are available"
}

# Get user inputs
get_user_inputs() {
    echo ""
    print_info "Please provide the following information:"
    echo ""

    # Project name
    read -p "$(echo -e ${BLUE}Enter project name [my_project]: ${NC})" PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-my_project}

    if [[ ! $PROJECT_NAME =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        print_error "Project name must be a valid Python package name: letters, numbers, and underscores only, and it cannot start with a number."
        exit 1
    fi

    # Database name
    read -p "$(echo -e ${BLUE}Enter database name [${PROJECT_NAME}_db]: ${NC})" DB_NAME
    DB_NAME=${DB_NAME:-${PROJECT_NAME}_db}

    if [[ ! $DB_NAME =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        print_error "Database name must use letters, numbers, and underscores only, and it cannot start with a number."
        exit 1
    fi

    # Database user
    read -p "$(echo -e ${BLUE}Enter database user [postgres]: ${NC})" DB_USER
    DB_USER=${DB_USER:-postgres}

    # Database password
    read -sp "$(echo -e ${BLUE}Enter database password [postgres]: ${NC})" DB_PASSWORD
    echo ""
    DB_PASSWORD=${DB_PASSWORD:-postgres}

    # Database host
    read -p "$(echo -e ${BLUE}Enter database host [localhost]: ${NC})" DB_HOST
    DB_HOST=${DB_HOST:-localhost}

    # Database port
    read -p "$(echo -e ${BLUE}Enter database port [5432]: ${NC})" DB_PORT
    DB_PORT=${DB_PORT:-5432}

    if [[ ! $DB_PORT =~ ^[0-9]+$ ]]; then
        print_error "Database port must be numeric."
        exit 1
    fi

    # Project directory
    read -p "$(echo -e ${BLUE}Enter project directory path [${TEMPLATE_PARENT_DIR}/${PROJECT_NAME}]: ${NC})" PROJECT_DIR
    PROJECT_DIR=${PROJECT_DIR:-${TEMPLATE_PARENT_DIR}/${PROJECT_NAME}}

    # Django secret key - generate without Django dependency
    DJANGO_SECRET_KEY=$(python3 -c 'import secrets; import string; chars = string.ascii_letters + string.digits + "!@#$%^&*(-_=+)"; print("".join(secrets.choice(chars) for _ in range(50)))')
    JWT_SIGNING_KEY=$(python3 -c 'import secrets; import string; chars = string.ascii_letters + string.digits + "!@#$%^&*(-_=+)"; print("".join(secrets.choice(chars) for _ in range(50)))')

    echo ""
    print_info "Summary of your inputs:"
    echo "  Project Name: $PROJECT_NAME"
    echo "  Database Name: $DB_NAME"
    echo "  Database User: $DB_USER"
    echo "  Database Host: $DB_HOST"
    echo "  Database Port: $DB_PORT"
    echo "  Project Directory: $PROJECT_DIR"
    echo ""

    read -p "$(echo -e ${YELLOW}Is this correct? [y/N]: ${NC})" CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
}

# Create project directory
create_project_directory() {
    print_info "Creating project directory..."

    if [ -d "$PROJECT_DIR" ]; then
        print_warning "Directory $PROJECT_DIR already exists"
        read -p "$(echo -e ${YELLOW}Do you want to continue? This may overwrite existing files. [y/N]: ${NC})" OVERWRITE
        if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
            print_error "Setup cancelled by user"
            exit 1
        fi
    else
        mkdir -p "$PROJECT_DIR"
    fi

    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

    case "$PROJECT_DIR/" in
        "$SCRIPT_DIR/"*)
            print_error "Project directory cannot be the template directory or any folder inside it. Choose a sibling directory outside: $SCRIPT_DIR"
            exit 1
            ;;
    esac

    print_success "Project directory created/verified"
}

# Copy template files
copy_template_files() {
    print_info "Copying template files..."

    if [ "$PROJECT_DIR" = "$SCRIPT_DIR" ]; then
        print_error "Project directory cannot be the template directory itself."
        exit 1
    fi

    # The user already approved overwrite in create_project_directory.
    # Remove prior generated app folders so stale files cannot survive.
    rm -rf "$PROJECT_DIR/backend" "$PROJECT_DIR/frontend"

    # Copy backend
    cp -r "$SCRIPT_DIR/backend" "$PROJECT_DIR/"

    # Copy frontend
    cp -r "$SCRIPT_DIR/frontend" "$PROJECT_DIR/"

    # Copy project-level utilities that remain useful after installation.
    for file in .editorconfig QUICKSTART.md setup_database.sh; do
        if [ -e "$SCRIPT_DIR/$file" ]; then
            cp -R "$SCRIPT_DIR/$file" "$PROJECT_DIR/$file"
        fi
    done

    # Rename Django project folder
    mv "$PROJECT_DIR/backend/{{PROJECT_NAME}}" "$PROJECT_DIR/backend/$PROJECT_NAME"

    if [ -f "$PROJECT_DIR/setup_database.sh" ]; then
        chmod +x "$PROJECT_DIR/setup_database.sh"
    fi

    print_success "Template files copied"
}

# Replace placeholders in files
replace_placeholders() {
    print_info "Replacing placeholders in files..."

    local escaped_project_name
    local escaped_db_name
    escaped_project_name=$(escape_sed_replacement "$PROJECT_NAME")
    escaped_db_name=$(escape_sed_replacement "$DB_NAME")

    # Find and replace in all files
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        find "$PROJECT_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.json" -o -name "*.html" -o -name "*.md" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.sh" -o -name ".env*" \) -exec sed -i '' "s/{{PROJECT_NAME}}/$escaped_project_name/g" {} +
        find "$PROJECT_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.json" -o -name "*.html" -o -name "*.md" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.sh" -o -name ".env*" \) -exec sed -i '' "s/{{DB_NAME}}/$escaped_db_name/g" {} +
    else
        # Linux
        find "$PROJECT_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.json" -o -name "*.html" -o -name "*.md" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.sh" -o -name ".env*" \) -exec sed -i "s/{{PROJECT_NAME}}/$escaped_project_name/g" {} +
        find "$PROJECT_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.json" -o -name "*.html" -o -name "*.md" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.sh" -o -name ".env*" \) -exec sed -i "s/{{DB_NAME}}/$escaped_db_name/g" {} +
    fi

    print_success "Placeholders replaced"
}

# Create .env files
create_env_files() {
    print_info "Creating .env files..."

    # Backend .env
    cat > "$PROJECT_DIR/backend/.env" << EOF
# Django settings
DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY
JWT_SIGNING_KEY=$JWT_SIGNING_KEY
DEBUG=True
ENVIRONMENT=development
APP_ORIGIN=http://localhost:3000
PUBLIC_APP_URL=http://localhost:3000
API_ORIGIN=http://localhost:8000
TRUST_X_FORWARDED_PROTO=False

# Database settings
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT

# Redis settings
USE_REDIS=False
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
# TRUSTED_PROXY_IPS=

# Celery
CELERY_BROKER_URL=redis://127.0.0.1:6379/2
CELERY_RESULT_BACKEND=redis://127.0.0.1:6379/2

# Signup protection
# SIGNUP_REGISTER_BURST_RATE=1/15s
# SIGNUP_REGISTER_SHORT_WINDOW_RATE=3/10m
# SIGNUP_REGISTER_SUSTAINED_RATE=10/h
# SIGNUP_CAPTCHA_TTL_SECONDS=600
# SIGNUP_FORM_MIN_AGE_SECONDS=3
# SIGNUP_FORM_MAX_AGE_SECONDS=3600
# SIGNUP_DISPOSABLE_EMAIL_BLOCKLIST=
# SIGNUP_DISPOSABLE_EMAIL_ALLOWLIST=

# Email — set these before going to production
# In dev, console backend prints emails to the terminal (no SMTP needed)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=
EMAIL_PORT=587
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
EMAIL_USE_TLS=True
DEFAULT_FROM_EMAIL=no-reply@example.com

# Social login — backend-only provider credentials
GOOGLE_OAUTH_CLIENT_ID=
GOOGLE_OAUTH_CLIENT_SECRET=
FACEBOOK_OAUTH_CLIENT_ID=
FACEBOOK_OAUTH_CLIENT_SECRET=
FACEBOOK_GRAPH_API_VERSION=v25.0
GITHUB_OAUTH_CLIENT_ID=
GITHUB_OAUTH_CLIENT_SECRET=

# Stripe — add your keys from https://dashboard.stripe.com/apikeys
STRIPE_SECRET_KEY=
STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=

# bKash — add your merchant credentials from the bKash developer portal
BKASH_APP_KEY=
BKASH_APP_SECRET=
BKASH_USERNAME=
BKASH_PASSWORD=
BKASH_BASE_URL=https://tokenized.sandbox.bka.sh/v1.2.0-beta
EOF

    # Frontend .env
    cat > "$PROJECT_DIR/frontend/.env" << 'EOF'
BACKEND_URL=http://localhost:8000
NEXT_PUBLIC_API_URL=/api
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
NEXT_PUBLIC_DJANGO_ADMIN_URL=http://localhost:8000/admin
EOF

    print_success ".env files created"
}

# Setup backend
setup_backend() {
    print_info "Setting up Django backend..."

    cd "$PROJECT_DIR/backend"

    # Create virtual environment
    print_info "Creating Python virtual environment..."
    python3 -m venv venv

    # Activate virtual environment
    source venv/bin/activate

    # Upgrade pip
    print_info "Upgrading pip..."
    pip install --upgrade pip

    # Install requirements
    print_info "Installing Python dependencies..."
    pip install -r requirements.txt

    print_success "Backend setup complete"
}

# Setup database
setup_database() {
    print_info "Setting up PostgreSQL database..."

    # Check if database exists
    DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME && echo "yes" || echo "no")

    if [ "$DB_EXISTS" == "yes" ]; then
        print_warning "Database $DB_NAME already exists"
        read -p "$(echo -e ${YELLOW}Do you want to drop and recreate it? [y/N]: ${NC})" DROP_DB
        if [[ $DROP_DB =~ ^[Yy]$ ]]; then
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "DROP DATABASE $DB_NAME;"
            print_success "Database dropped"
        else
            print_info "Using existing database"
            return
        fi
    fi

    # Create database
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $DB_NAME;"

    print_success "Database created"
}

# Run migrations
run_migrations() {
    print_info "Running Django migrations..."

    cd "$PROJECT_DIR/backend"
    source venv/bin/activate

    python manage.py makemigrations
    python manage.py migrate

    print_success "Migrations complete"
}

# Seed default subscription plans
seed_plans() {
    print_info "Seeding default subscription plans (Free / Pro / Enterprise)..."

    cd "$PROJECT_DIR/backend"
    source venv/bin/activate

    python manage.py shell -c "
from subscriptions.models import Plan
plans = [
    {'slug': 'free',       'name': 'Free',       'tier': 0, 'max_items': 3,  'price_monthly': 0,  'price_yearly': 0,   'bkash_price_monthly': 0,    'bkash_price_yearly': 0,     'currency': 'USD', 'is_active': True, 'features': ['Up to 3 items', 'Basic features', 'Community support']},
    {'slug': 'pro',        'name': 'Pro',         'tier': 1, 'max_items': 25, 'price_monthly': 29, 'price_yearly': 290, 'bkash_price_monthly': 2900, 'bkash_price_yearly': 29000, 'currency': 'USD', 'is_active': True, 'features': ['Up to 25 items', 'All Pro features', 'Priority support']},
    {'slug': 'enterprise', 'name': 'Enterprise',  'tier': 2, 'max_items': 0,  'price_monthly': 99, 'price_yearly': 990, 'bkash_price_monthly': 9900, 'bkash_price_yearly': 99000, 'currency': 'USD', 'is_active': True, 'features': ['Unlimited items', 'All Enterprise features', 'Dedicated support']},
]
for p in plans:
    Plan.objects.update_or_create(slug=p['slug'], defaults=p)
print('Plans seeded successfully.')
"

    print_success "Subscription plans seeded"
}

# Create superuser
create_superuser() {
    print_info "Creating Django superuser..."
    echo ""
    print_warning "You will be prompted to create a superuser account"

    cd "$PROJECT_DIR/backend"
    source venv/bin/activate

    python manage.py createsuperuser

    print_success "Superuser created"
}

# Setup frontend
setup_frontend() {
    print_info "Setting up Next.js frontend..."

    cd "$PROJECT_DIR/frontend"

    # Install npm packages
    print_info "Installing npm dependencies (this may take a few minutes)..."
    if [ -f package-lock.json ]; then
        npm ci
    else
        npm install
    fi

    print_success "Frontend setup complete"
}

# Create start scripts
create_start_scripts() {
    print_info "Creating start scripts..."

    # Backend start script
    cat > "$PROJECT_DIR/start_backend.sh" << 'EOF'
#!/bin/bash
cd backend
source venv/bin/activate
python manage.py runserver 8000
EOF

    # Frontend start script
    cat > "$PROJECT_DIR/start_frontend.sh" << 'EOF'
#!/bin/bash
cd frontend
npm run dev
EOF

    # Combined start script
    cat > "$PROJECT_DIR/start.sh" << 'EOF'
#!/bin/bash

# Start backend in background
./start_backend.sh &
BACKEND_PID=$!

# Start frontend in background
./start_frontend.sh &
FRONTEND_PID=$!

echo "Backend running on http://localhost:8000"
echo "Frontend running on http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both servers"

# Wait for user interrupt
trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait
EOF

    chmod +x "$PROJECT_DIR/start_backend.sh"
    chmod +x "$PROJECT_DIR/start_frontend.sh"
    chmod +x "$PROJECT_DIR/start.sh"

    print_success "Start scripts created"
}

# Print final instructions
print_final_instructions() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             Setup Complete! 🎉                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_info "Your project is ready at: $PROJECT_DIR"
    echo ""
    print_info "To start your project:"
    echo "  1. Start backend:  ./start_backend.sh"
    echo "  2. Start frontend: ./start_frontend.sh"
    echo "  3. Or both:        ./start.sh"
    echo ""
    print_info "Useful commands:"
    echo "  Backend:  cd $PROJECT_DIR/backend && source venv/bin/activate"
    echo "  Frontend: cd $PROJECT_DIR/frontend && npm run dev"
    echo ""
    print_info "URLs:"
    echo "  Frontend:       http://localhost:3000"
    echo "  Backend API:    http://localhost:8000/api"
    echo "  Django Admin:   http://localhost:8000/admin"
    echo ""
    print_info "Configure your credentials — open these files and fill in the blanks:"
    echo ""
    echo -e "  ${YELLOW}$PROJECT_DIR/backend/.env${NC}"
    echo "    EMAIL_BACKEND / EMAIL_HOST / EMAIL_HOST_USER / EMAIL_HOST_PASSWORD"
    echo "      → dev default: console backend (emails print to terminal, no SMTP needed)"
    echo "      → production: set EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend"
    echo ""
    echo "    DJANGO_SECRET_KEY / JWT_SIGNING_KEY"
    echo "      → generated for local development; replace both with strong random values in production"
    echo ""
    echo "    STRIPE_SECRET_KEY / STRIPE_PUBLISHABLE_KEY / STRIPE_WEBHOOK_SECRET"
    echo "      → get keys from https://dashboard.stripe.com/apikeys"
    echo "      → set webhook endpoint: POST /api/payments/stripe/webhook/"
    echo ""
    echo "    BKASH_APP_KEY / BKASH_APP_SECRET / BKASH_USERNAME / BKASH_PASSWORD"
    echo "      → get credentials from the bKash merchant portal"
    echo "      → change BKASH_BASE_URL to production URL before going live"
    echo ""
    echo "    GOOGLE_OAUTH_CLIENT_ID / GOOGLE_OAUTH_CLIENT_SECRET"
    echo "    FACEBOOK_OAUTH_CLIENT_ID / FACEBOOK_OAUTH_CLIENT_SECRET"
    echo "    GITHUB_OAUTH_CLIENT_ID / GITHUB_OAUTH_CLIENT_SECRET"
    echo "      → add provider credentials, restart backend, then enable providers in the admin panel"
    echo ""
    echo -e "  ${YELLOW}$PROJECT_DIR/frontend/.env${NC}"
    echo "    BACKEND_URL"
    echo "      → server-side rewrite target used by Next.js (/api/* -> BACKEND_URL/api/*)"
    echo ""
    echo "    NEXT_PUBLIC_API_URL"
    echo "      → dev default: /api (Next.js rewrite keeps browser requests same-origin)"
    echo ""
    echo "    NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"
    echo "      → your Stripe publishable key (pk_live_... or pk_test_...)"
    echo ""
    echo "    NEXT_PUBLIC_DJANGO_ADMIN_URL"
    echo "      → optional admin shortcut shown in the frontend admin area"
    echo ""
    print_info "Next steps:"
    echo "  1. Fill in the credentials above in backend/.env and frontend/.env"
    echo "  2. Update Plan prices/limits in Django admin (/admin) or via shell"
    echo "  3. Review QUICKSTART.md and frontend/README.md for documentation"
    echo "  4. Start building your app features!"
    echo ""
    print_success "Happy coding! 🚀"
}

offer_template_cleanup() {
    echo ""
    read -p "$(echo -e ${YELLOW}Installation is complete. Do you want to delete the template folder at ${SCRIPT_DIR}? [y/N]: ${NC})" DELETE_TEMPLATE

    if [[ $DELETE_TEMPLATE =~ ^[Yy]$ ]]; then
        cd "$TEMPLATE_PARENT_DIR"
        rm -rf "$SCRIPT_DIR"
        print_success "Deleted template folder: $SCRIPT_DIR"
    else
        print_info "Kept template folder at: $SCRIPT_DIR"
    fi
}

# Main execution
main() {
    check_requirements
    get_user_inputs
    create_project_directory
    copy_template_files
    replace_placeholders
    create_env_files
    setup_database
    setup_backend
    run_migrations
    seed_plans

    echo ""
    read -p "$(echo -e ${BLUE}Do you want to create a superuser now? [Y/n]: ${NC})" CREATE_SU
    if [[ ! $CREATE_SU =~ ^[Nn]$ ]]; then
        create_superuser
    else
        print_info "You can create a superuser later with: python manage.py createsuperuser"
    fi

    setup_frontend
    create_start_scripts
    print_final_instructions
    offer_template_cleanup
}

# Run main function
main
