#!/bin/bash

# Cross-platform PostgreSQL database setup script
# This script creates a PostgreSQL database and user for the project

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
PLATFORM=""
PLATFORM_LABEL=""
MINIMUM_POSTGRES_MAJOR="12"
POSTGRES_BREW_FORMULA="${POSTGRES_BREW_FORMULA:-postgresql@17}"
POSTGRES_WINDOWS_PACKAGE="${POSTGRES_WINDOWS_PACKAGE:-PostgreSQL.PostgreSQL.17}"
AUTO_INSTALL_REQUIREMENTS="${AUTO_INSTALL_REQUIREMENTS:-ask}"
POSTGRES_INSTALLED_BY_SETUP=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          PostgreSQL Database Setup                   ║${NC}"
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

detect_platform() {
    case "$OSTYPE" in
        darwin*)
            PLATFORM="macos"
            PLATFORM_LABEL="macOS"
            ;;
        linux*)
            PLATFORM="linux"
            PLATFORM_LABEL="Linux"
            ;;
        msys*|cygwin*|win32*|mingw*)
            PLATFORM="windows"
            PLATFORM_LABEL="Windows (Git Bash)"
            ;;
        *)
            print_error "Unsupported platform: $OSTYPE"
            exit 1
            ;;
    esac
}

prepend_path() {
    local directory="$1"
    if [[ -d "$directory" && ":$PATH:" != *":$directory:"* ]]; then
        PATH="$directory:$PATH"
        export PATH
        hash -r 2>/dev/null || true
    fi
}

configure_postgres_path() {
    local program_files_path=""
    local psql_executable=""
    local program_files_native="${PROGRAMFILES:-${ProgramFiles:-}}"

    if [[ "$PLATFORM" == "macos" ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            if [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        if command -v brew >/dev/null 2>&1 && brew list "$POSTGRES_BREW_FORMULA" >/dev/null 2>&1; then
            prepend_path "$(brew --prefix "$POSTGRES_BREW_FORMULA")/bin"
        fi
    elif [[ "$PLATFORM" == "windows" && -n "$program_files_native" ]] && command -v cygpath >/dev/null 2>&1; then
        program_files_path=$(cygpath -u "$program_files_native")
        psql_executable=$(find "$program_files_path/PostgreSQL" -type f -iname psql.exe -print 2>/dev/null | sort -Vr | head -n 1 || true)
        [[ -n "$psql_executable" ]] && prepend_path "$(dirname "$psql_executable")"
    fi
}

postgres_version_supported() {
    local detected_major
    command -v psql >/dev/null 2>&1 || return 1
    detected_major=$(psql --version 2>/dev/null | sed -E 's/^[^0-9]*([0-9]+).*/\1/')
    [[ "$detected_major" =~ ^[0-9]+$ ]] && (( detected_major >= MINIMUM_POSTGRES_MAJOR ))
}

run_privileged() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        print_error "Administrator access is required to install PostgreSQL."
        return 1
    fi
}

install_homebrew() {
    local installer_file

    command -v brew >/dev/null 2>&1 && return 0
    command -v curl >/dev/null 2>&1 || {
        print_error "curl is required to install Homebrew."
        return 1
    }

    print_info "Installing Homebrew with its official installer..."
    installer_file=$(mktemp "${TMPDIR:-/tmp}/nextdjango-homebrew-installer.XXXXXX")
    curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer_file"
    /bin/bash "$installer_file"
    rm -f "$installer_file"
    configure_postgres_path
    command -v brew >/dev/null 2>&1
}

linux_package_manager() {
    local manager
    for manager in apt-get dnf yum pacman; do
        command -v "$manager" >/dev/null 2>&1 && { echo "$manager"; return 0; }
    done
    return 1
}

install_linux_postgres() {
    local manager
    manager=$(linux_package_manager) || {
        print_error "A supported package manager is required (apt-get, dnf, yum, or pacman)."
        return 1
    }

    case "$manager" in
        apt-get)
            run_privileged apt-get update
            run_privileged apt-get install -y postgresql postgresql-client
            ;;
        dnf|yum)
            run_privileged "$manager" install -y postgresql postgresql-server
            if command -v postgresql-setup >/dev/null 2>&1; then
                run_privileged postgresql-setup --initdb >/dev/null 2>&1 || true
            fi
            ;;
        pacman)
            run_privileged pacman -Sy --needed --noconfirm postgresql
            ;;
    esac

    if command -v systemctl >/dev/null 2>&1; then
        run_privileged systemctl enable --now postgresql >/dev/null 2>&1 || true
    elif command -v service >/dev/null 2>&1; then
        run_privileged service postgresql start >/dev/null 2>&1 || true
    fi
}

install_postgres() {
    print_info "Installing PostgreSQL for $PLATFORM_LABEL..."
    case "$PLATFORM" in
        macos)
            install_homebrew
            brew install "$POSTGRES_BREW_FORMULA"
            prepend_path "$(brew --prefix "$POSTGRES_BREW_FORMULA")/bin"
            brew services start "$POSTGRES_BREW_FORMULA" >/dev/null 2>&1 || true
            ;;
        linux)
            install_linux_postgres
            ;;
        windows)
            if ! command -v winget >/dev/null 2>&1 && ! command -v winget.exe >/dev/null 2>&1; then
                print_error "WinGet is required to install PostgreSQL automatically on Windows 10/11."
                return 1
            fi
            print_warning "The installer may ask for a PostgreSQL superuser password."
            "$(command -v winget 2>/dev/null || command -v winget.exe)" install --id "$POSTGRES_WINDOWS_PACKAGE" -e --interactive --accept-source-agreements --accept-package-agreements
            configure_postgres_path
            ;;
    esac
    POSTGRES_INSTALLED_BY_SETUP=1
}

# Check for PostgreSQL and offer to install it when needed.
check_postgres() {
    print_info "Checking PostgreSQL installation..."

    configure_postgres_path
    if ! postgres_version_supported; then
        local answer=""
        print_warning "PostgreSQL $MINIMUM_POSTGRES_MAJOR+ and psql are required but not active."
        case "$AUTO_INSTALL_REQUIREMENTS" in
            1|yes|true|always) ;;
            0|no|false|never)
                print_error "Automatic installation is disabled by AUTO_INSTALL_REQUIREMENTS=$AUTO_INSTALL_REQUIREMENTS."
                exit 1
                ;;
            ask)
                read -p "$(echo -e ${YELLOW}Download and activate PostgreSQL now? [Y/n]: ${NC})" answer
                [[ "$answer" =~ ^[Nn]$ ]] && exit 1
                ;;
            *)
                print_error "AUTO_INSTALL_REQUIREMENTS must be ask, yes, or no."
                exit 1
                ;;
        esac
        install_postgres
        postgres_version_supported || {
            print_error "PostgreSQL was installed but psql is not available. Open a new terminal and run this script again."
            exit 1
        }
    fi

    print_success "Using $(psql --version)"
}

# Check if PostgreSQL is running
check_postgres_running() {
    print_info "Checking if PostgreSQL is running..."

    if ! pg_isready -q; then
        print_error "PostgreSQL is not running"
        echo ""
        print_info "Start the PostgreSQL service for $PLATFORM_LABEL, then run this script again."
        exit 1
    fi

    print_success "PostgreSQL is running"
}

# Get user inputs
get_inputs() {
    echo ""
    print_info "Database Configuration"
    echo ""

    read -p "$(echo -e ${BLUE}Enter database name: ${NC})" DB_NAME
    while [ -z "$DB_NAME" ]; do
        print_warning "Database name cannot be empty"
        read -p "$(echo -e ${BLUE}Enter database name: ${NC})" DB_NAME
    done
    if [[ ! $DB_NAME =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        print_error "Database name must use letters, numbers, and underscores only, and it cannot start with a number."
        exit 1
    fi

    read -p "$(echo -e ${BLUE}Enter database user [postgres]: ${NC})" DB_USER
    DB_USER=${DB_USER:-postgres}
    if [[ ! $DB_USER =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        print_error "Database user must use letters, numbers, and underscores only, and it cannot start with a number."
        exit 1
    fi

    read -sp "$(echo -e ${BLUE}Enter database password [leave empty for no password]: ${NC})" DB_PASSWORD
    echo ""

    read -p "$(echo -e ${BLUE}Enter database host [localhost]: ${NC})" DB_HOST
    DB_HOST=${DB_HOST:-localhost}

    read -p "$(echo -e ${BLUE}Enter database port [5432]: ${NC})" DB_PORT
    DB_PORT=${DB_PORT:-5432}
    if [[ ! $DB_PORT =~ ^[0-9]+$ ]]; then
        print_error "Database port must be numeric."
        exit 1
    fi

    echo ""
    print_info "Database Configuration Summary:"
    echo "  Database Name: $DB_NAME"
    echo "  Database User: $DB_USER"
    echo "  Database Host: $DB_HOST"
    echo "  Database Port: $DB_PORT"
    echo ""

    read -p "$(echo -e ${YELLOW}Is this correct? [y/N]: ${NC})" CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
}

bootstrap_installed_postgres_role() {
    local escaped_password
    local password_clause=""
    local role_sql

    [[ "$POSTGRES_INSTALLED_BY_SETUP" -eq 1 ]] || return 0
    [[ "$DB_HOST" == "localhost" || "$DB_HOST" == "127.0.0.1" ]] || return 0
    [[ "$PLATFORM" != "windows" ]] || return 0

    if [[ -n "$DB_PASSWORD" ]]; then
        escaped_password=${DB_PASSWORD//\'/\'\'}
        password_clause=" PASSWORD '$escaped_password'"
    fi
    role_sql="DO \$\$ BEGIN
IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE \"$DB_USER\" WITH LOGIN CREATEDB$password_clause;
ELSE
    ALTER ROLE \"$DB_USER\" WITH LOGIN CREATEDB$password_clause;
END IF;
END \$\$;"

    print_info "Configuring the local PostgreSQL role '$DB_USER'..."
    if [[ "$PLATFORM" == "macos" ]]; then
        psql -d postgres -v ON_ERROR_STOP=1 -c "$role_sql"
    elif [[ "${EUID:-$(id -u)}" -eq 0 ]] && command -v runuser >/dev/null 2>&1; then
        runuser -u postgres -- psql -d postgres -v ON_ERROR_STOP=1 -c "$role_sql"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -u postgres psql -d postgres -v ON_ERROR_STOP=1 -c "$role_sql"
    else
        print_error "Administrator access is required to configure the freshly installed PostgreSQL role."
        return 1
    fi
}

# Create database
create_database() {
    print_info "Creating database..."

    # Check if database exists
    if [ -n "$DB_PASSWORD" ]; then
        DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$DB_NAME" && echo "yes" || echo "no")
    else
        DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$DB_NAME" && echo "yes" || echo "no")
    fi

    if [ "$DB_EXISTS" == "yes" ]; then
        print_warning "Database '$DB_NAME' already exists"
        read -p "$(echo -e ${YELLOW}Do you want to drop and recreate it? [y/N]: ${NC})" DROP_DB

        if [[ $DROP_DB =~ ^[Yy]$ ]]; then
            print_warning "Dropping database '$DB_NAME'..."
            if [ -n "$DB_PASSWORD" ]; then
                PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;"
            else
                psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;"
            fi
            print_success "Database dropped"
        else
            print_info "Keeping existing database"
            return 0
        fi
    fi

    # Create database
    print_info "Creating database '$DB_NAME'..."
    if [ -n "$DB_PASSWORD" ]; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"
    fi

    print_success "Database '$DB_NAME' created successfully"
}

# Create database user (if needed)
create_user() {
    local escaped_password

    if [ "$DB_USER" == "postgres" ]; then
        print_info "Using default 'postgres' user"
        return 0
    fi

    print_info "Checking if user '$DB_USER' exists..."

    # Check if user exists
    if [ -n "$DB_PASSWORD" ]; then
        USER_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" 2>/dev/null)
    else
        USER_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" 2>/dev/null)
    fi

    if [ "$USER_EXISTS" == "1" ]; then
        print_warning "User '$DB_USER' already exists"
        return 0
    fi

    print_info "Creating user '$DB_USER'..."
    if [ -n "$DB_PASSWORD" ]; then
        escaped_password=${DB_PASSWORD//\'/\'\'}
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "CREATE USER \"$DB_USER\" WITH PASSWORD '$escaped_password';"
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\";"
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "CREATE USER \"$DB_USER\";"
        psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\";"
    fi

    print_success "User '$DB_USER' created successfully"
}

# Test connection
test_connection() {
    print_info "Testing database connection..."

    if [ -n "$DB_PASSWORD" ]; then
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; then
            print_success "Database connection successful"
        else
            print_error "Failed to connect to database"
            exit 1
        fi
    else
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; then
            print_success "Database connection successful"
        else
            print_error "Failed to connect to database"
            exit 1
        fi
    fi
}

# Print final instructions
print_instructions() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Database Setup Complete! 🎉                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_info "Database Configuration:"
    echo "  Database Name: $DB_NAME"
    echo "  Database User: $DB_USER"
    echo "  Database Host: $DB_HOST"
    echo "  Database Port: $DB_PORT"
    echo ""
    print_info "Connection String:"
    if [ -n "$DB_PASSWORD" ]; then
        echo "  postgresql://$DB_USER:****@$DB_HOST:$DB_PORT/$DB_NAME"
    else
        echo "  postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
    fi
    echo ""
    print_info "Update your .env file with these values:"
    echo "  DB_NAME=$DB_NAME"
    echo "  DB_USER=$DB_USER"
    if [ -n "$DB_PASSWORD" ]; then
        echo "  DB_PASSWORD=$DB_PASSWORD"
    fi
    echo "  DB_HOST=$DB_HOST"
    echo "  DB_PORT=$DB_PORT"
    echo ""
    print_success "You can now run Django migrations!"
}

# Main execution
main() {
    detect_platform
    check_postgres
    check_postgres_running
    get_inputs
    bootstrap_installed_postgres_role
    create_database
    create_user
    test_connection
    print_instructions
}

# Run main only when this file is executed, not when its helpers are sourced.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
