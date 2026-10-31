# Finpay API

## About the Project

Finpay API is a Ruby on Rails API project that implements PostgreSQL schema-based multi-tenancy using Apartment (`ros-apartment`).

Each company has its own tenant schema, while company records remain in the `public` schema. The API implements authentication using Devise and JWT, tenant binding using verified token claims, refresh-token rotation, and authorization using Pundit policies.

## Features

- PostgreSQL database integration

- Schema-based multi-tenancy using Apartment

- Company model with name and subdomain validations

- Company provisioning service with transaction rollback

- Safe tenant switching in application code

- API authentication using Devise and JWT

- Short-lived access tokens with a 15-minute lifetime

- Refresh-token rotation and revocation

- JWT denylist for revoked access tokens

- Tenant binding based on the verified JWT `company_id` claim

- Role-based authorization using Pundit

- Record-level access control for admin and member roles

- Request, model, service, and policy specifications

- Redis integration through Docker Compose

## Technologies Used

- Ruby 4.0.7

- Ruby on Rails (API mode)

- PostgreSQL

- Redis

- Apartment (`ros-apartment`)

- Devise

- `devise-jwt`

- Pundit

- RSpec Rails

- FactoryBot Rails

- Faker

- SimpleCov

- RuboCop

- Brakeman

- Bundler Audit

## Codebase Tour

| Path | Purpose |

|---|---|

| `app/models/` | Active Record models, including `Company`, `User`, `RefreshToken`, and `JwtDenylist` |

| `app/controllers/api/v1/` | API authentication, protected endpoints, and user endpoints |

| `app/controllers/concerns/tenant_loader.rb` | Validates JWT-based tenant context and switches tenant schemas |

| `app/services/` | Business logic, including company provisioning and authentication services |

| `app/policies/` | Pundit policies for authorization |

| `config/initializers/apartment.rb` | Configures schema-based multi-tenancy |

| `config/initializers/devise.rb` | Configures Devise |

| `config/routes.rb` | Defines API endpoints |

| `db/migrate/` | Database migration files |

| `db/schema.rb` | Database schema snapshot |

| `spec/requests/api/` | Authentication and authorization request specifications |

| `spec/models/` | Model specifications |

| `spec/policies/` | Authorization policy specifications |

| `spec/services/` | Authentication service and tenant-switching specifications |

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

- **Public schema:** Company records and the JWT denylist are stored in the `public` schema.

- **Tenant schemas:** Each company's `subdomain` is used as its tenant schema name.

- **Tenant-scoped models:** User records and refresh tokens are stored in the corresponding tenant schema.

- **Excluded models:** `Company` and `JwtDenylist` are excluded from tenant schemas.

- **Tenant discovery:** Apartment obtains tenant names from `Company.pluck(:subdomain)`.

- **Subdomain validation:** Subdomains must start with a lowercase letter and contain lowercase letters, digits, or underscores. Their length must be between 3 and 31 characters.

- **Reserved names:** PostgreSQL schema names such as `public`, `pg_catalog`, `information_schema`, and `pg_toast` are rejected.

- **Read-only attribute:** The `Company` model declares `subdomain` as read-only after persistence.

### Tenant-aware development

When implementing features that access company-owned data:

- Ensure database reads and writes execute in the correct tenant context.

- Derive the tenant identifier from the verified JWT, not from a client-supplied tenant header or request parameter.

- Validate that the authenticated user belongs to the selected company.

- Restore the previous tenant context after each request, including when an exception occurs.

- Add tests for tenant isolation and tenant switching.

- Keep company-level records and the JWT denylist in the public schema.

## Authentication and Authorization

### Authentication flow

The API uses Devise and `devise-jwt` for authentication.

1. A user registers or logs in using the authentication endpoints.

2. Login identifies the company and authenticates the user's credentials within that company's tenant schema.

3. A successful login returns an access token containing the authenticated user's identity and `company_id`.

4. Access tokens have a configured lifetime of approximately 15 minutes.

5. Protected requests validate the access token before using its `company_id` to select the tenant schema.

6. The application checks that the user exists within the selected tenant before allowing the request to proceed.

The server must derive tenant context from a verified token claim. Client-provided tenant identifiers must not override the token's tenant context.

### Authentication endpoints

| Method | Endpoint | Purpose |

|---|---|---|

| `POST` | `/api/v1/auth/register` | Register a user |

| `POST` | `/api/v1/auth/login` | Authenticate a user and issue tokens |

| `DELETE` | `/api/v1/auth/logout` | Revoke the current access token |

| `POST` | `/api/v1/auth/refresh` | Rotate a refresh token |

| `GET` | `/api/v1/protected` | Example protected endpoint |

| `GET` | `/api/v1/users/:id` | Retrieve a user subject to authorization |

### Access-token revocation

Revoked access-token JTIs are recorded in `public.jwt_denylist`. Protected requests reject tokens that have been revoked.

### Refresh tokens

Refresh tokens are stored as digests rather than plaintext tokens. The refresh flow checks expiration and revocation, invalidates the previous token during rotation, and issues a replacement token.

The configured refresh-token lifetime is seven days.

### Roles and authorization

The application defines two user roles:

- **Admin:** Can access records permitted by the admin policy within the authenticated tenant.

- **Member:** Can access their own user record, but cannot access another member's record.

Pundit policies enforce authorization at the record level. Authorization should default to denial unless an explicit policy permits the action.

### Authentication and authorization endpoints

Example requests can be tested using Postman or another HTTP client. Use the response token as a Bearer token when calling protected endpoints:

```http

Authorization: Bearer YOUR_ACCESS_TOKEN

```

Never commit real access tokens, refresh tokens, credentials, or other secrets.

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

    # Example: User.limit(10).to_a

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

Authentication and authorization tests are located under `spec/requests/api/`, with model, service, and policy tests in their respective directories.

## Code Quality and Security Checks

Run the project's quality and security checks:

```bash

bundle exec rubocop

bundle exec brakeman

bundle exec bundler-audit check --update

bundle exec rails zeitwerk:check

```

These checks help identify Ruby style issues, potential Rails security vulnerabilities, known vulnerable dependencies, and autoloading problems.

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

- Never trust tenant identifiers supplied by the client in place of verified JWT claims.

- Apply Pundit authorization to protected record access.

- Keep the JWT denylist in `public` and tenant-specific user and refresh-token data isolated by schema.
