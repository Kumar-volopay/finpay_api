# Finpay API

## About the Project

Finpay API is a Ruby on Rails API project that implements PostgreSQL schema-based multi-tenancy using Apartment (`ros-apartment`).

Each company has its own tenant schema, while company records remain in the `public` schema.

## Features

- PostgreSQL database integration
- Schema-based multi-tenancy using Apartment
- Company model with name and subdomain validations
- Company provisioning service with transaction rollback
- Safe tenant switching in application code
- Redis integration through Docker Compose

## Technologies Used

- Ruby 4.0.7
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

## Codebase Tour

The project follows the standard Ruby on Rails application structure.

| Path | Purpose |
|---|---|
| `app/models/` | Active Record models, including `Company` |
| `app/services/` | Business logic, including company provisioning |
| `app/controllers/` | Handles HTTP requests and responses |
| `config/initializers/apartment.rb` | Configures schema-based multi-tenancy |
| `config/database.yml` | Configures PostgreSQL connections |
| `db/migrate/` | Database migration files |
| `db/schema.rb` | Database schema snapshot |
| `spec/models/` | Model specifications |
| `spec/services/` | Service and tenant-switching specifications |
| `spec/requests/` | Request specifications |
| `compose.yaml` | Local PostgreSQL and Redis services |
| `bin/setup` | Sets up dependencies, Docker services, and the database |
| `config/deploy.yml` | Kamal deployment configuration |

## Ruby Version

The project specifies Ruby `4.0.7` in `.ruby-version`.

Verify your installed Ruby version:

```bash
ruby --version
```

Use the specified Ruby version when setting up the project to maintain consistency across development environments.

## First-Run Setup

### Prerequisites

- Ruby 4.0.7
- Bundler
- Docker Desktop with Docker Compose
- Git

### Setup steps

1. Clone the repository and open a terminal in the project directory.

2. Run the setup script:

   ```bash
   ruby bin/setup --skip-server
   ```

3. On the first run, if `.env` does not exist, the script copies `.env.example` to `.env` and stops. Open `.env` and set `DATABASE_PASSWORD` to your local development database password.

4. Run the setup script again:

   ```bash
   ruby bin/setup --skip-server
   ```

5. Verify that PostgreSQL and Redis are running and healthy:

   ```bash
   docker compose ps
   ```

6. If necessary, prepare the database:

   ```bash
   ruby bin/rails db:prepare
   ```

7. Run the test suite:

   ```bash
   bundle exec rspec
   ```

To start the Rails server after setup:

```bash
ruby bin/rails server
```

**Environment variables:** Keep `.env` local and never commit it. The `.env.example` file should contain placeholder values only.

## Docker Setup

Docker Compose runs PostgreSQL and Redis for local development.

The local services use the following host ports:

| Service | Host address | Container port |
|---|---|---|
| PostgreSQL | `127.0.0.1:5433` | `5432` |
| Redis | `127.0.0.1:6380` | `6379` |

The services are bound to the local machine rather than all network interfaces. The PostgreSQL development and test configurations connect through port `5433`.

To start the services manually:

```bash
docker compose up -d --wait
```

To inspect their status:

```bash
docker compose ps
```

## Multi-Tenancy Conventions

The application uses PostgreSQL schema-based multi-tenancy through Apartment.

- **Public schema:** Company records are stored in the `public` schema.
- **Tenant schemas:** Each company's `subdomain` is used as its tenant schema name.
- **Excluded model:** The `Company` model is excluded from tenant schemas so company records remain accessible from the public schema.
- **Tenant discovery:** Apartment obtains tenant names from `Company.pluck(:subdomain)`.
- **Subdomain validation:** Subdomains must start with a lowercase letter and contain lowercase letters, digits, or underscores. Their length must be between 3 and 31 characters.
- **Reserved names:** PostgreSQL schema names such as `public`, `pg_catalog`, `information_schema`, and `pg_toast` are rejected.
- **Read-only attribute:** The `Company` model declares `subdomain` as read-only after persistence.

### Tenant-aware development

When implementing features that access company-owned data:

- Ensure database reads and writes execute in the correct tenant context.
- Avoid unintentionally accessing one company's data while operating in another company's tenant.
- Add tests for tenant isolation and tenant switching when introducing tenant-aware behavior.
- Keep company-level records in the public schema.

## Safe Rails Console Usage

Use the Rails console carefully, particularly when inspecting tenant-specific data.

Start the development console:

```bash
ruby bin/rails console
```

Inspect company records:

```ruby
Company.pluck(:id, :name, :subdomain)
```

Inspect configured tenant names:

```ruby
Apartment.tenant_names
```

To inspect tenant-specific records, switch to a known tenant using Apartment's block-based switching API:

```ruby
tenant = Company.first&.subdomain

if tenant
  Apartment::Tenant.switch(tenant) do
    # Read tenant-specific records here.
    # Replace YourModel with an actual tenant-scoped model.
    # Example: YourModel.limit(10).to_a
  end
end
```

The block-based API restores the previous tenant context when the block finishes, including when an exception occurs.

**Safety guidelines:**

- Prefer read-only queries when inspecting data.
- Avoid destructive database operations in the console.
- Never reset, drop, or delete data in a shared or production environment without explicit authorization.
- Verify the current tenant context before running tenant-specific operations.

## Run Tests

Run the complete RSpec test suite:

```bash
bundle exec rspec
```

Run a specific spec file when debugging:

```bash
bundle exec rspec spec/models/company_spec.rb
```

## Code Quality and Security Checks

Run the project's quality and security checks:

```bash
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit check --update
```

These checks help identify Ruby style issues, potential Rails security vulnerabilities, and known vulnerable dependencies.

## Deployment Flow

The project uses a Kamal deployment configuration in `config/deploy.yml`.

Before deploying:

1. Verify the target server addresses and container registry.
2. Configure required deployment secrets, including `RAILS_MASTER_KEY`, using the project's deployment secret mechanism.
3. Configure the production database connection and the `FINPAY_API_DATABASE_PASSWORD` environment variable.
4. Verify production database availability, image registry access, and persistent storage configuration.
5. Run the project's tests and security checks.
6. Follow the deployment commands and approval process established by your team.
7. Verify application health and logs after deployment.

The configuration currently contains example-looking values for the server address (`192.168.0.1`) and registry (`localhost:5555`). These must be verified and replaced with the actual deployment infrastructure values before deploying.

Kamal commands are available through the project's `bin/kamal` executable. Do not deploy using unverified server, registry, or secret settings.

## Security Notes

- Never commit `.env`, database passwords, access tokens, or private keys.
- Keep `.env.example` limited to placeholder values.
- Store production secrets through the approved deployment secret mechanism.
- Validate tenant context before reading or modifying company-specific data.
