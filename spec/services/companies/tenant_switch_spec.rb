require "rails_helper"

RSpec.describe "Company tenant switching" do
  let(:company) { create(:company) }
  let(:subdomain) { company.subdomain }

  it "keeps Company accessible inside a tenant and restores the previous tenant" do
    track_tenant_schema(subdomain)
    Apartment::Tenant.create(subdomain)

    expect(Apartment::Tenant.current).to eq("public")

    Apartment::Tenant.switch(subdomain) do
      expect(Apartment::Tenant.current).to eq(subdomain)

      # Company is excluded from tenant schemas and remains in public.
      expect { Company.count }.not_to raise_error
      expect(Company.count).to eq(1)
    end

    expect(Apartment::Tenant.current).to eq("public")
  end

  it "isolates category records between tenants" do
    tenant_one = tenant_subdomain("tenant")
    tenant_two = tenant_subdomain("tenant")

    track_tenant_schema(tenant_one)
    track_tenant_schema(tenant_two)

    Apartment::Tenant.create(tenant_one)
    Apartment::Tenant.create(tenant_two)

    Apartment::Tenant.switch(tenant_one) do
      Category.create!(name: "Food")
    end

    Apartment::Tenant.switch(tenant_two) do
      Category.create!(name: "Travel")
    end

    Apartment::Tenant.switch(tenant_one) do
      expect(Category.pluck(:name)).to eq([ "Food" ])
    end

    Apartment::Tenant.switch(tenant_two) do
      expect(Category.pluck(:name)).to eq([ "Travel" ])
    end
  end
end
