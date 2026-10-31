
require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "does not switch tenants when X-Company-Id is provided" do
    expect(Apartment::Tenant.current).to eq("public")

    get "/up", headers: { "X-Company-Id" => "unknown-company" }

    expect(response).to have_http_status(:ok)
    expect(Apartment::Tenant.current).to eq("public")
  end
end
