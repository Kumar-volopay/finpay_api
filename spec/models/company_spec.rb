
require "rails_helper"
require "securerandom"

RSpec.describe Company, type: :model do
  let(:subdomain) { "company_#{SecureRandom.hex(4)}" }

  describe "validations" do
    subject { build(:company) }

    it "is valid with a name and valid subdomain" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      subject.name = nil

      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires a subdomain" do
      subject.subdomain = nil

      expect(subject).not_to be_valid
      expect(subject.errors[:subdomain]).to include("can't be blank")
    end

    it "rejects an invalid subdomain format" do
      subject.subdomain = "1invalid"

      expect(subject).not_to be_valid
      expect(subject.errors[:subdomain]).to include("is invalid")
    end

    it "rejects duplicate subdomains" do
      create(:company, subdomain: subdomain)
      duplicate = build(:company, subdomain: subdomain)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:subdomain]).to include("has already been taken")
    end

    it "rejects reserved PostgreSQL schema names" do
      %w[public pg_catalog information_schema pg_toast].each do |reserved_name|
        company = build(:company, subdomain: reserved_name)

        expect(company).not_to be_valid
        expect(company.errors[:subdomain]).to include("is reserved")
      end
    end
  end

  describe "readonly attributes" do
    it "does not allow the persisted subdomain to change" do
      company = create(:company, subdomain: subdomain)

      expect do
        company.update!(subdomain: "newco")
      end.to raise_error(ActiveRecord::ReadonlyAttributeError)

      expect(company.reload.subdomain).to eq(subdomain)
    end
  end

  describe "database schema" do
    it "keeps the companies table in the public schema" do
      schema = ActiveRecord::Base.connection.select_value(<<~SQL)
        SELECT table_schema
        FROM information_schema.tables
        WHERE table_name = 'companies'
          AND table_type = 'BASE TABLE'
      SQL

      expect(schema).to eq("public")
    end
  end
end
