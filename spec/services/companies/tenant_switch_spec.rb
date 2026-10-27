
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
end
