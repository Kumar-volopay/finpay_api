
require "swagger_helper"

RSpec.describe "Protected API", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Rswag Protected Company",
      prefix: "rswag_protected"
    )
  end

  let(:user) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "protected_user@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: :member
      )
    end
  end

  let(:access_token) do
    post "/api/v1/auth/login",
      params: {
        subdomain: company.subdomain,
        email: user.email,
        password: "TestPass123!"
      }

    response.parsed_body.fetch("access_token")
  end

  path "/api/v1/protected" do
    get "Check authenticated access" do
      tags "Authentication"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      response "200", "authenticated successfully" do
        let(:Authorization) { "Bearer #{access_token}" }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to be_present
        end
      end

      response "401", "authentication required" do
        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
