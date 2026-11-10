
require "swagger_helper"

RSpec.describe "Invitations API", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Rswag Invitations Company",
      prefix: "rswag_invitations"
    )
  end

  let(:admin) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "invitation_admin@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: :admin
      )
    end
  end

  let(:member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "invitation_member@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: :member
      )
    end
  end

  let(:admin_token) do
    post "/api/v1/auth/login",
      params: {
        subdomain: company.subdomain,
        email: admin.email,
        password: "TestPass123!"
      }

    response.parsed_body.fetch("access_token")
  end

  let(:member_token) do
    post "/api/v1/auth/login",
      params: {
        subdomain: company.subdomain,
        email: member.email,
        password: "TestPass123!"
      }

    response.parsed_body.fetch("access_token")
  end

  path "/api/v1/invitations" do
    post "Create an invitation" do
      tags "Invitations"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: :invitation, in: :body, required: true,
                schema: {
                  type: :object,
                  properties: {
                    email: { type: :string, format: :email }
                  },
                  required: [ "email" ]
                }

      response "201", "invitation created" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:invitation) do
          { email: "new_employee@example.com" }
        end

        run_test!
      end

      response "403", "admin authorization required" do
        let(:Authorization) { "Bearer #{member_token}" }
        let(:invitation) do
          { email: "new_employee@example.com" }
        end

        run_test!
      end

      response "401", "authentication required" do
        let(:Authorization) { nil }
        let(:invitation) do
          { email: "new_employee@example.com" }
        end

        run_test!
      end
    end
  end
end
