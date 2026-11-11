# Finpay API

Finpay API is a Ruby on Rails JSON API for company expense management. It supports company-level data isolation, JWT authentication, role-based authorization, expense workflows, and receipt file uploads with background OCR-status processing.

## Features

- Company registration and provisioning with PostgreSQL schema-based multi-tenancy (Apartment).
- JWT access-token authentication, refresh-token rotation, and token revocation.
- Tenant-aware request handling: the verified JWT determines the company context.
- Admin/member authorization with Pundit policies.
- Expense creation, listing, filtering, pagination, and workflow actions such as approval, cancellation, and reimbursement.
- Receipt uploads using Active Storage (PDF, JPEG, and PNG; maximum 10 MB).
- Background receipt processing with Sidekiq. OCR text is currently simulated; this project does not yet integrate a real OCR engine.
- RSpec tests and CI checks for RuboCop, Brakeman, Bundler Audit, and RSpec.

## Tech stack

- Ruby 3.4.12
- Ruby on Rails 8.1 (API mode)
- PostgreSQL
- Redis and Sidekiq
- Apartment (`ros-apartment`)
- Devise and `devise-jwt`
- Pundit
- Active Storage
- RSpec Rails, FactoryBot, Faker, and SimpleCov
- RuboCop, Brakeman, and Bundler Audit

## Requirements

The recommended local setup uses Docker Compose. Install:

- Git
- Docker Desktop with Docker Compose
- Postman (optional, for API testing)

If you run Rails outside Docker, install the Ruby version specified in `.ruby-version` and Bundler as well.

## Clone and run the project

```bash
git clone https://github.com/Kumar-volopay/finpay_api.git
cd finpay_api
```

1. Create your local environment file if the repository provides an example:

   ```bash
   cp .env.example .env
   ```

   Review `.env.example` and set the required local values in `.env`. Do not commit `.env` or put real secrets in documentation.

2. Build and start the application and its Docker Compose services:

   ```bash
   docker compose up -d --build
   ```

3. Check that the services are running:

   ```bash
   docker compose ps
   ```

4. Prepare the database:

   ```bash
   docker compose exec web ruby bin/rails db:prepare
   ```

5. If the project provides development seed data and you want to load it, run:

   ```bash
   docker compose exec web ruby bin/rails db:seed
   ```

6. Check the Rails application at:

   ```text
   http://127.0.0.1:3000
   ```

The API base URL used in the examples below is `http://127.0.0.1:3000`. If your Compose configuration maps the web service to a different host port, use that port instead.

### Useful Docker commands

```bash
# View service status
docker compose ps

# Follow application logs
docker compose logs -f web

# Follow background worker logs
docker compose logs -f worker

# Open a Rails console
docker compose exec web ruby bin/rails console

# Stop the services
docker compose down
```

## How the application works

### Multi-tenancy

The application uses PostgreSQL schema-based multi-tenancy through Apartment:

- The `public` schema stores company-level records and the JWT denylist.
- Each company has a tenant schema identified by its subdomain.
- Tenant-specific records, including users and refresh tokens, are stored in the relevant tenant schema.
- For protected requests, the application verifies the JWT and derives the tenant from its `company_id` claim. A client-supplied tenant identifier must not override this context.
- Tenant context is restored after request processing, including when an exception occurs.

### Authentication and authorization

The API uses Devise and `devise-jwt` for authentication and Pundit for authorization.

1. A user registers or logs in through the authentication endpoints.
2. A successful login returns an access token and refresh token.
3. Send the access token as a Bearer token on protected requests.
4. The API verifies the token, resolves the company tenant, and checks that the user belongs to that tenant.
5. Pundit policies decide whether the user can access or change the requested record.

Access tokens are short-lived (configured for 15 minutes). Refresh tokens are rotated and have a configured seven-day lifetime. Revoked access-token identifiers are stored in the public JWT denylist.

The application has admin and member roles. Authorization is tenant-scoped and record-level; a member must not be able to access another member's protected records.

## API endpoints

All API endpoints are under `/api/v1`.

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/v1/auth/register` | Register a user |
| `POST` | `/api/v1/auth/login` | Log in and receive tokens |
| `DELETE` | `/api/v1/auth/logout` | Revoke the current access token |
| `POST` | `/api/v1/auth/refresh` | Rotate a refresh token |
| `GET` | `/api/v1/protected` | Example authenticated endpoint |
| `GET` | `/api/v1/users/:id` | Retrieve a user subject to policy authorization |
| `POST` | `/api/v1/expenses/:expense_id/receipts` | Upload a receipt for an expense |
| `GET` | `/api/v1/expenses/:expense_id/receipts/:id` | Retrieve receipt metadata |

For the complete and current list of expense CRUD and workflow routes, run:

```bash
docker compose exec web ruby bin/rails routes
```

## Test the API with Postman

You can use Postman or any HTTP client. The following steps describe the end-to-end API testing flow. Use test accounts and tokens generated in your own local environment; never copy real credentials or tokens into the README.

### 1. Create a Postman environment

Create an environment named `Finpay Local` and add:

| Variable | Initial value |
|---|---|
| `base_url` | `http://127.0.0.1:3000` |
| `access_token` | Leave empty until login |
| `refresh_token` | Leave empty until login |
| `expense_id` | Leave empty until an expense is created |
| `receipt_id` | Leave empty until a receipt is uploaded |

Select this environment before sending requests.

### 2. Register or log in

Send a registration request if you need a new test user:

```http
POST {{base_url}}/api/v1/auth/register
Content-Type: application/json
```

Use the registration JSON fields required by the API. Then log in:

```http
POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
```

Use the company and user credentials configured for your local test data. From the successful login response, copy the access token and refresh token into the `access_token` and `refresh_token` environment variables.

### 3. Call protected endpoints

For protected requests, choose **Authorization → Bearer Token** in Postman and set the token to:

```text
{{access_token}}
```

Alternatively, add this header:

```http
Authorization: Bearer {{access_token}}
```

### 4. Exercise the expense workflow

Use the expense endpoints listed by `rails routes` to create an expense, retrieve/list expenses, and exercise the workflow actions available to the authenticated role. Test with separate admin and member accounts where applicable. Save the created expense ID as `expense_id` for the receipt request below.

Verify tenant isolation by authenticating as a user from a different company and attempting to access the first company's expense. The other company's user should not gain access to that record.

### 5. Upload a receipt

A receipt belongs to an existing expense. In Postman, create this request:

```http
POST {{base_url}}/api/v1/expenses/{{expense_id}}/receipts
```

- Select **Body → form-data**.
- Add a key named `receipt[file]`.
- Change the key type from **Text** to **File**.
- Select a PDF, JPEG, or PNG file no larger than 10 MB.
- Keep Bearer Token authorization enabled.

Do not use a plain `file` key. The controller expects the nested multipart field `receipt[file]`.

A successful upload returns receipt metadata. The initial OCR status is normally `pending`; the Sidekiq worker processes it in the background. Retrieve the receipt metadata with:

```http
GET {{base_url}}/api/v1/expenses/{{expense_id}}/receipts/{{receipt_id}}
```

Save the returned receipt ID in `receipt_id`. The worker currently writes simulated OCR text and updates the status; it does not extract text from the uploaded document using a real OCR service.

### 6. Test refresh and logout

- Send the refresh request to `POST {{base_url}}/api/v1/auth/refresh` using the refresh-token request format expected by the API. Save the newly issued tokens because refresh-token rotation invalidates the previous refresh token.
- Send `DELETE {{base_url}}/api/v1/auth/logout` with the access token to revoke the current token.
- After logout, verify that the revoked access token can no longer access protected endpoints.

## Run tests and quality checks

Run commands inside the web container so they use the project's Docker environment.

```bash
# Full RSpec suite
docker compose exec web env RAILS_ENV=test bundle exec rspec

# One spec file
docker compose exec web env RAILS_ENV=test bundle exec rspec spec/models/company_spec.rb

# Ruby style checks
docker compose exec web bundle exec rubocop

# Rails security scan
docker compose exec web bundle exec brakeman --no-pager

# Dependency vulnerability audit
docker compose exec web bundle exec bundler-audit check --update

# Rails autoloading check
docker compose exec web ruby bin/rails zeitwerk:check
```

CI runs these checks on pull requests. The RSpec CI job runs with coverage enabled.

## Project structure

| Path | Responsibility |
|---|---|
| `app/controllers/api/v1/` | Versioned API endpoints |
| `app/controllers/concerns/tenant_loader.rb` | JWT validation and tenant switching |
| `app/models/` | Active Record models and associations |
| `app/services/` | Business operations and application workflows |
| `app/policies/` | Pundit authorization rules |
| `app/serializers/` | API response serialization |
| `app/workers/` | Sidekiq background jobs |
| `config/initializers/apartment.rb` | Apartment configuration |
| `config/routes.rb` | API route definitions |
| `db/migrate/` | Database migrations |
| `db/schema.rb` | Current database schema snapshot |
| `spec/` | RSpec model, request, service, policy, and integration tests |
| `compose.yaml` | Local application and dependency services |
| `.github/workflows/ci.yml` | Pull-request CI workflow |

## Security notes

- Keep `.env`, master keys, database passwords, JWTs, and refresh tokens out of Git.
- Use placeholder values only in `.env.example` and documentation.
- Never trust a tenant ID supplied by a request when a verified JWT claim determines the tenant.
- Keep authorization checks on protected records and test cross-tenant access.
- Do not run destructive database commands against shared or production environments.

## Deployment

The repository contains a Kamal configuration in `config/deploy.yml`. Its server and registry values must be checked against the actual deployment infrastructure, and production secrets must be configured securely before deployment. Do not deploy using example or unverified infrastructure values.
