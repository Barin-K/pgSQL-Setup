#!/bin/bash

# Exit if undefined variables are used.
set -e
set -u

# Logging functions
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}
log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1"
}

# Check if PostgreSQL is installed.
if ! command -v psql &> /dev/null; then
    log_error "PostgreSQL is not installed. Please install PostgreSQL first."
    exit 1
fi

# Check if required environment variables for credentials are set.
if [ -z "${ADMIN_PASS:-}" ]; then
    log_error "ADMIN_PASS environment variable is not set. Please set it and try again."
    exit 1
fi

if [ -z "${VIEW_PASS:-}" ]; then
    log_error "VIEW_PASS environment variable is not set. Please set it and try again."
    exit 1
fi

# Debug information
log_message "Debug: Current environment variables:"
log_message "PGUSER: $PGUSER"
log_message "PGHOST: $PGHOST"
log_message "PGPORT: $PGPORT"

# Variables: Adjust these if needed.
DB_NAME="books_db"
# SUPERUSER="postgres"  # Adjust if your PostgreSQL superuser is different.
# ADMIN_USER="books_admin"
# VIEW_USER="books_view"

log_message "Creating database ${DB_NAME}..."


# Drop and create database
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};" || { log_error "Failed to drop database ${DB_NAME}"; exit 1; }
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d postgres -c "CREATE DATABASE ${DB_NAME};" || { log_error "Failed to create database ${DB_NAME}"; exit 1; }

PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};" || { log_error "Failed to drop database ${DB_NAME}"; exit 1; }
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE ${DB_NAME};" || { log_error "Failed to create database ${DB_NAME}"; exit 1; }

log_message "Database ${DB_NAME} created successfully."

log_message "Setting up the database schema, roles, advanced features, and sample data..."

# Create the books table with timestamp columns.
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d "${DB_NAME}" <<'EOF'
CREATE TABLE IF NOT EXISTS books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    sub_title VARCHAR(255),
    author VARCHAR(255) NOT NULL,
    publisher VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
EOF

log_message "Books table created."

#  Create roles and grant privileges using environment variables for passwords.
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d ${DB_NAME} <<EOF
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d "${DB_NAME}" <<'EOF'
DO
\$do\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'books_admin') THEN
        CREATE ROLE books_admin WITH LOGIN PASSWORD '$ADMIN_PASS';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'books_view') THEN
        CREATE ROLE books_view WITH LOGIN PASSWORD '$VIEW_PASS';
    END IF;
END
\$do\$;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO books_admin;
GRANT CONNECT ON DATABASE $DB_NAME TO books_view;

GRANT ALL PRIVILEGES ON TABLE books TO books_admin;
GRANT SELECT ON TABLE books TO books_view;
EOF

log_message "Roles created and privileges granted."

# Create a trigger function to automatically update the updated_at column.
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d ${DB_NAME} <<'EOF'
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d "${DB_NAME}" <<'EOF'
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_books_updated_at
BEFORE UPDATE ON books
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
EOF

log_message "Trigger and function for auto-updating 'updated_at' column created."

# Create a view to aggregate and format book details.
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d ${DB_NAME} <<'EOF'
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d "${DB_NAME}" <<'EOF'
CREATE OR REPLACE VIEW book_details AS
SELECT 
    book_id,
    title,
    sub_title,
    author,
    publisher,
    to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at,
    to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') as updated_at
FROM books;
EOF

# Grant privileges on the view for both roles.
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d ${DB_NAME} <<'EOF'
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d "${DB_NAME}" <<'EOF'
GRANT SELECT ON book_details TO books_admin;
GRANT SELECT ON book_details TO books_view;
EOF

log_message "View 'book_details' created."

#  Insert sample data for testing.
# psql -h 127.0.0.1 -p 5432 -U ${SUPERUSER} -d ${DB_NAME} <<'EOF'
PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -h 127.0.0.1 -p 5432 -d "${DB_NAME}" <<'EOF'
INSERT INTO books (title, sub_title, author, publisher)
VALUES 
    ('Terraform Up & Running', 'Writing Infrastructure as Code', 'Yevgeniy Brikman', 'O''Reilly Media'),
    ('97 Things Every Cloud Engineer Should Know', 'Collective Wisdom from the Experts', 'Emily Freeman', 'O''Reilly Media'),
    ('Harry Potter', 'And the Chambers of Secrets', 'AJ. K. Rowling', 'Bloomsbury Publishing');
EOF

log_message "Sample data inserted."
log_message "Database setup completed successfully!"
