# Finpay API

## About the Project

Finpay API is a Ruby on Rails API project that implements PostgreSQL schema-based multi-tenancy using Apartment.

Each company has its own tenant schema, while company records remain in the `public` schema.

## Features

- PostgreSQL database integration
- Schema-based multi-tenancy using Apartment
- Company model with name and subdomain validations
- Company provisioning service with transaction rollback
- Safe tenant switching in application code
- Redis integration through Docker Compose

## Technologies Used

- Ruby
- Ruby on Rails (API mode)
- PostgreSQL
- Redis
- Apartment (`ros-apartment`)

## Additional Gems

- **RSpec Rails** – Automated testing
- **FactoryBot Rails** – Test data factories
- **Faker** – Sample test data generation
- **SimpleCov** – Code coverage reporting
- **RuboCop** – Ruby code style checks
- **Brakeman** – Rails security scanning
- **Bundler Audit** – Dependency vulnerability checks

## Docker Setup

Docker Compose is configured to run PostgreSQL and Redis.

Set the `DATABASE_PASSWORD` environment variable before starting the containers.

```bash
docker compose up -d
```

## Run Tests

```bash
bundle exec rspec
```

## Code Quality and Security Checks

```bash
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit check --update
```
