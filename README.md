__PostgreSQL Database Setup__:
This repository contains a PostgreSQL database setup script and GitHub Actions workflow for creating and managing a books database with admin and view roles.

Purpose: Initialize a secure book database with proper user management, advanced PostgreSQL automation (trigger/function, view), robust error handling, and sample data.
Created: February 2025


__Script Features__:

Database Creation: Creates a books_db database

Table Structure: Books table with fields for:
- Title
- Sub-title
- Author
- Publisher
- Timestamps (created_at, updated_at)


User Roles:
- books_admin: Full CRUD privileges
- books_view: Read-only access

Features
- Functions: Auto-update timestamp trigger
- Views: book_details view for formatted book information
- Sample data population

__Prerequisites__
1. PostgreSQL 14 or later
1. Docker for local testing. (optional)
1. GitHub account with repository access
1. DBeaver, pgAdmin or similar PostgreSQL client (optional)

__Local Testing__

__Option 1: Using Local PostgreSQL Installation__

1. __Install and Start the PostgreSQL service__:

**macOS:**
```bash
brew services start postgresql
```
**Linux:**
```bash
sudo service postgresql 
```

2. __Set required environment variables__:
```bash
export POSTGRES_PASSWORD=your_password
export ADMIN_PASS=admin_password
export VIEW_PASS=view_password
```
3. __Run the Setup Script__:
```bash
chmod +x ./pgsql.sh
./pgsql.sh
```

__Option 2: Using Docker (Alternative)__

If you prefer using Docker or don't have PostgreSQL installed locally:

1. __Start PostgreSQL Container__:

```bash
docker run -d \
  --name postgres-test \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  postgres:14
```
2. __Follow steps 2-3 from Option 1__


__CI/CD Pipeline (GitHub Actions)__

__Setup__:

1. __Configure repository secrets__:
```bash
POSTGRES_PASSWORD  # Password for PostgreSQL superuser
POSTGRES_USER      # PostgreSQL superuser
ADMIN_PASS        # Password for books_admin role
VIEW_PASS         # Password for books_view role
```

2. __The workflow automatically runs on__:
- Push to ci-cd branch
- Pull requests to ci-cd branch

__Pipeline Features__:
- Automated PostgreSQL container setup
- Environment configuration
- Database initialization
- Automated cleanup