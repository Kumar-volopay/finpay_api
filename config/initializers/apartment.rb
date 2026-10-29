# frozen_string_literal: true

require "apartment"

Apartment.configure do |config|
  # Keep Company and JwtDenylist records in the public schema.
  config.excluded_models = [
    "Company",
    "JwtDenylist"
  ]

  # Use PostgreSQL schemas for tenant isolation.
  config.use_schemas = true
  config.use_sql = true

  # Exclude configured models from tenant schema cloning.
  config.pg_exclude_clone_tables = true

  # Keep the public schema accessible.
  config.persistent_schemas = [ "public" ]

  # Tenant schemas will be managed by application code.
  config.tenant_names = -> { Company.pluck(:subdomain) }
end
