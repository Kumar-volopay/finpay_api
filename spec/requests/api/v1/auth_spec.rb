require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let!(:company) do
    Companies::Provision.call(
      name: "Auth Request Spec Company",
      subdomain: "auth_request_spec"
    )
  end

  let(:registration_params) do
    {
      subdomain: company.subdomain,
      email: "new_member@example.com",
      password: "TestPass123!",
      password_confirmation: "TestPass123!"
    }
  end

  def login_params
    {
      subdomain: company.subdomain,
      email: "new_member@example.com",
      password: "TestPass123!"
    }
  end

  def create_member
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "new_member@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!"
      )
    end
  end

  describe "POST /api/v1/auth/register" do
    it "registers a member and returns access and refresh tokens" do
      post "/api/v1/auth/register", params: registration_params

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("user", "email"))
        .to eq("new_member@example.com")
      expect(response.parsed_body["access_token"]).to be_present
      expect(response.parsed_body["refresh_token"]).to be_present
    end
  end

  describe "POST /api/v1/auth/login" do
    it "logs in a member and returns a token containing company_id" do
      create_member

      post "/api/v1/auth/login", params: login_params

      expect(response).to have_http_status(:ok)

      access_token = response.parsed_body["access_token"]
      payload = Authentication::TokenService.decode(access_token)

      expect(payload["company_id"]).to eq(company.id)
      expect(response.parsed_body["refresh_token"]).to be_present
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login",
           params: login_params.merge(password: "WrongPassword!")

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "revokes the access token and rejects it on a protected endpoint" do
      create_member

      post "/api/v1/auth/login", params: login_params
      expect(response).to have_http_status(:ok)

      access_token = response.parsed_body["access_token"]

      delete "/api/v1/auth/logout",
             headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:no_content)

      get "/api/v1/users/1",
          headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
