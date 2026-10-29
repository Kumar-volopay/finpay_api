
require "securerandom"

module TenantSchemaCleanup
  def tenant_subdomain(prefix = "tenant")
    "#{prefix}_#{SecureRandom.hex(4)}"
  end

  def track_tenant_schema(subdomain)
    if ActiveRecord::Base.connection.schema_exists?(subdomain)
      raise "Refusing to track existing tenant schema: #{subdomain}"
    end

    @tenant_schemas_to_clean ||= []
    @tenant_schemas_to_clean << subdomain
  end
end

RSpec.configure do |config|
  config.include TenantSchemaCleanup

  config.after(:each) do
    next unless defined?(Apartment::Tenant)

    Apartment::Tenant.reset

    Array(@tenant_schemas_to_clean).uniq.each do |subdomain|
      if ActiveRecord::Base.connection.schema_exists?(subdomain)
        Apartment::Tenant.drop(subdomain)
      end
    end
  ensure
    @tenant_schemas_to_clean = []
    Apartment::Tenant.reset if defined?(Apartment::Tenant)
  end
end
