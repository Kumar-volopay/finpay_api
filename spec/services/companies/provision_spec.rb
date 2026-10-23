
require "rails_helper"

RSpec.describe Companies::Provision do
  describe ".call" do
    let(:name) { "Acme Corporation" }
    let(:subdomain) { "acme" }

    it "creates a company and its tenant schema" do
      company = described_class.call(name: name, subdomain: subdomain)

      expect(company).to be_persisted
      expect(company.name).to eq(name)
      expect(company.subdomain).to eq(subdomain)

      expect(
        ActiveRecord::Base.connection.schema_exists?(subdomain)
      ).to be(true)
    ensure
      Apartment::Tenant.reset

      if ActiveRecord::Base.connection.schema_exists?(subdomain)
        Apartment::Tenant.drop(subdomain)
      end
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
      schema_name = "rollback_check"
      original_create = Apartment::Tenant.method(:create)
      schema_creation_attempted = false

      allow(Apartment::Tenant).to receive(:create).with(schema_name) do |tenant|
        original_create.call(tenant)
        schema_creation_attempted = true

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
    ensure
      Apartment::Tenant.reset

      if schema_creation_attempted &&
         ActiveRecord::Base.connection.schema_exists?(schema_name)
        Apartment::Tenant.drop(schema_name)
      end
    end
  end
end
