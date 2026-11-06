
require "swagger_helper"

RSpec.describe "Users API", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Rswag Users Company",
      prefix: "rswag_users"
    )
  end

  let(:admin) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "users_admin@example.com",
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
        email: "users_member@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: :member
      )
    end
  end

  let(:other_member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "other_member@example.com",
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

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Show a user" do
      tags "Users"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      response "200", "user details returned" do
        let(:id) { member.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test!
      end

      response "200", "member can view their own profile" do
        let(:id) { member.id }
        let(:Authorization) { "Bearer #{member_token}" }

        run_test!
      end

      response "404", "member cannot access another user's profile" do
        let(:id) { other_member.id }
        let(:Authorization) { "Bearer #{member_token}" }

        run_test!
      end

      response "401", "authentication required" do
        let(:id) { member.id }
        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
