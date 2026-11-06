require "swagger_helper"

RSpec.describe "Authentication API", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Rswag Auth Company",
      prefix: "rswag_auth"
    )
  end

  def create_member
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "rswag_member@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!"
      )
    end
  end

  path "/api/v1/auth/login" do
    post "Login to FinPay" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          subdomain: { type: :string, example: "acme" },
          email: { type: :string, example: "member@example.com" },
          password: { type: :string, example: "TestPass123!" }
        },
        required: %w[subdomain email password]
      }

      response "200", "successful login" do
        let(:credentials) do
          {
            subdomain: company.subdomain,
            email: "rswag_member@example.com",
            password: "TestPass123!"
          }
        end

        before { create_member }

        schema type: :object,
               properties: {
                 access_token: { type: :string },
                 refresh_token: { type: :string }
               }

        run_test!
      end

      response "401", "invalid credentials" do
        let(:credentials) do
          {
            subdomain: company.subdomain,
            email: "unknown@example.com",
            password: "WrongPassword!"
          }
        end

        run_test!
      end

      response "429", "login rate limit exceeded" do
        let(:credentials) do
          {
            subdomain: company.subdomain,
            email: "rswag_member@example.com",
            password: "WrongPassword!"
          }
        end

        before do
          5.times do
            post "/api/v1/auth/login", params: credentials
          end
        end

        header "Retry-After", schema: {
          type: :integer,
          description: "Seconds until another login attempt is allowed"
        }

        run_test!
      end
    end
  end

  path "/api/v1/auth/register" do
    post "Register using an invitation" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :registration, in: :body, required: true,
                schema: {
                  type: :object,
                  properties: {
                    subdomain: { type: :string },
                    email: { type: :string, format: :email },
                    password: { type: :string },
                    password_confirmation: { type: :string },
                    invitation_token: { type: :string }
                  },
                  required: %w[
                    subdomain email password
                    password_confirmation invitation_token
                  ]
                }

      let(:invitation_token) do
        Apartment::Tenant.switch(company.subdomain) do
          admin = create(:user, role: :admin)

          _invitation, token =
            Authentication::InvitationService.create(
              user: admin,
              email: "registered_member@example.com"
            )

          token
        end
      end

      response "201", "registration successful" do
        let(:registration) do
          {
            subdomain: company.subdomain,
            email: "registered_member@example.com",
            password: "TestPass123!",
            password_confirmation: "TestPass123!",
            invitation_token: invitation_token
          }
        end

        run_test!
      end

      response "401", "invalid invitation" do
        let(:registration) do
          {
            subdomain: company.subdomain,
            email: "registered_member@example.com",
            password: "TestPass123!",
            password_confirmation: "TestPass123!",
            invitation_token: "invalid-token"
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/logout" do
    delete "Logout and revoke authentication tokens" do
      tags "Authentication"
      consumes "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: :logout_payload, in: :body, required: true,
                schema: {
                  type: :object,
                  properties: {
                    refresh_token: { type: :string }
                  },
                  required: [ "refresh_token" ]
                }

      let(:logout_tokens) do
        create_member

        post "/api/v1/auth/login",
          params: {
            subdomain: company.subdomain,
            email: "rswag_member@example.com",
            password: "TestPass123!"
          }

        response.parsed_body
      end

      response "204", "successfully logged out" do
        let(:Authorization) do
          "Bearer #{logout_tokens.fetch('access_token')}"
        end

        let(:logout_payload) do
          { refresh_token: logout_tokens.fetch("refresh_token") }
        end

        run_test!
      end

      response "401", "invalid refresh token" do
        let(:Authorization) do
          "Bearer #{logout_tokens.fetch('access_token')}"
        end

        let(:logout_payload) do
          { refresh_token: "invalid-refresh-token" }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/refresh" do
    post "Refresh authentication tokens" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :refresh_credentials, in: :body,
                required: true, schema: {
                  type: :object,
                  properties: {
                    subdomain: { type: :string },
                    refresh_token: { type: :string }
                  },
                  required: %w[subdomain refresh_token]
                }

      let(:refresh_setup) do
        create_member

        post "/api/v1/auth/login",
          params: {
            subdomain: company.subdomain,
            email: "rswag_member@example.com",
            password: "TestPass123!"
          }

        response.parsed_body
      end

      response "200", "tokens successfully refreshed" do
        let(:refresh_credentials) do
          {
            subdomain: company.subdomain,
            refresh_token: refresh_setup.fetch("refresh_token")
          }
        end

        run_test!
      end

      response "401", "invalid refresh token" do
        let(:refresh_credentials) do
          {
            subdomain: company.subdomain,
            refresh_token: "invalid-refresh-token"
          }
        end

        run_test!
      end
    end
  end
end
