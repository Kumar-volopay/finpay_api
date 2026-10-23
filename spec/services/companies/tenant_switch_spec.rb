
require "rails_helper"

RSpec.describe "Company tenant switching" do
  let(:subdomain) { "acme" }

  it "switches to the specified tenant and restores the previous tenant" do
    Apartment::Tenant.create(subdomain)

    begin
      expect(Apartment::Tenant.current).to eq("public")

      Apartment::Tenant.switch(subdomain) do
        expect(Apartment::Tenant.current).to eq(subdomain)
      end

      expect(Apartment::Tenant.current).to eq("public")
    ensure
      Apartment::Tenant.reset

      if ActiveRecord::Base.connection.schema_exists?(subdomain)
        Apartment::Tenant.drop(subdomain)
      end
    end
  end
end
