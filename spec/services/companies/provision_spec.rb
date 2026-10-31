
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


    it "creates authentication tables, indexes, and constraints in the tenant schema" do
      track_tenant_schema(subdomain)

      described_class.call(name: name, subdomain: subdomain)

      connection = ActiveRecord::Base.connection
      quoted_schema = connection.quote(subdomain)

      tables = connection.select_values(<<~SQL)
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = #{quoted_schema}
      SQL

      expect(tables).to include("users", "refresh_tokens")

      indexes = connection.select_values(<<~SQL)
        SELECT indexname
        FROM pg_indexes
        WHERE schemaname = #{quoted_schema}
          AND tablename IN ('users', 'refresh_tokens')
      SQL

      expect(indexes).to include(
        "index_users_on_email",
        "index_users_on_jti",
        "index_refresh_tokens_on_token_digest",
        "index_refresh_tokens_on_user_id"
      )

      columns = connection.select_rows(<<~SQL)
        SELECT table_name, column_name, is_nullable
        FROM information_schema.columns
        WHERE table_schema = #{quoted_schema}
          AND table_name = 'refresh_tokens'
          AND column_name IN ('user_id', 'token_digest', 'expires_at')
      SQL

      expect(columns.size).to eq(3)
      expect(columns.map(&:last).uniq).to eq([ "NO" ])
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
