# frozen_string_literal: true

require "apartment"

Apartment.configure do |config|
  # Keep shared models in the public schema.
  config.excluded_models = [
    "Company",
    "JwtDenylist"
  ]

  # Use PostgreSQL schemas for tenant isolation.
  config.use_schemas = true
  config.use_sql = true

  # Exclude configured models from tenant schema cloning.
  config.pg_exclude_clone_tables = true

  # Do not keep public in the tenant search path.
  config.persistent_schemas = []

  # Tenant schemas are managed by application code.
  config.tenant_names = -> { Company.pluck(:subdomain) }
end
