
require "rails_helper"

RSpec.describe Companies::Provision do
  describe ".call" do
    let(:name) { "Test Corporation" }
    let(:subdomain) { tenant_subdomain("provision") }

    it "creates a company and its tenant schema" do
      track_tenant_schema(subdomain)

      company = described_class.call(name: name, subdomain: subdomain)

      expect(company).to be_persisted
      expect(company.name).to eq(name)
      expect(company.subdomain).to eq(subdomain)

      expect(
        ActiveRecord::Base.connection.schema_exists?(subdomain)
      ).to be(true)
    end

    it "rejects a duplicate subdomain" do
      create(:company, subdomain: subdomain)

      expect do
        described_class.call(
          name: "Another Company",
          subdomain: subdomain
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "rolls back the company and tenant schema if schema creation fails" do
      track_tenant_schema(subdomain)

      allow(Apartment::Tenant).to receive(:create)
        .with(subdomain)
        .and_raise(StandardError, "Schema creation failed")

      expect do
        described_class.call(name: name, subdomain: subdomain)
      end.to raise_error(StandardError, "Schema creation failed")

      Apartment::Tenant.reset

      expect(Company.exists?(subdomain: subdomain)).to be(false)

      expect(
        ActiveRecord::Base.connection.schema_exists?(subdomain)
      ).to be(false)
    end

    it "rolls back the company and schema if a later operation fails" do
      schema_name = tenant_subdomain("rollback")
      track_tenant_schema(schema_name)

      original_create = Apartment::Tenant.method(:create)

      allow(Apartment::Tenant).to receive(:create).with(schema_name) do |tenant|
        original_create.call(tenant)
        raise StandardError, "Failure after schema creation"
      end

      expect do
        described_class.call(
          name: "Rollback Test Company",
          subdomain: schema_name
        )
      end.to raise_error(
        StandardError,
        "Failure after schema creation"
      )

      Apartment::Tenant.reset

      expect(Company.exists?(subdomain: schema_name)).to be(false)

      expect(
        ActiveRecord::Base.connection.schema_exists?(schema_name)
      ).to be(false)
    end
  end
end
