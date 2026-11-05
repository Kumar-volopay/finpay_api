require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  before(:each) do
    Rails.cache.clear
  end

  let!(:company) do
    provision_test_tenant(
      name: "Auth Request Spec Company",
      prefix: "users_auth_spec"
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

  def create_invitation(email: "new_member@example.com")
    Apartment::Tenant.switch(company.subdomain) do
      admin = create(:user, role: :admin)

      _invitation, raw_token = Authentication::InvitationService.create(
        user: admin,
        email: email
      )

      raw_token
    end
  end

  describe "POST /api/v1/auth/register" do
    it "registers a member with a valid invitation" do
      invitation_token = create_invitation

      post "/api/v1/auth/register",
           params: registration_params.merge(
             invitation_token: invitation_token
           )

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("user", "email"))
        .to eq("new_member@example.com")
      expect(response.parsed_body.dig("user", "role")).to eq("member")
      expect(response.parsed_body["access_token"]).to be_present
      expect(response.parsed_body["refresh_token"]).to be_present
    end

    it "returns the same error for an unknown company" do
      post "/api/v1/auth/register",
           params: registration_params.merge(
             subdomain: "unknown_company",
             invitation_token: "invalid-token"
           )

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error")).to include(
  "code" => "invalid_invitation",
  "message" => "Invalid invitation",
  "details" => []
)
expect(response.parsed_body.dig("error", "request_id")).to be_present
    end

    it "rejects registration without an invitation" do
      post "/api/v1/auth/register", params: registration_params

      expect(response).to have_http_status(:unauthorized)
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
    it "revokes both access and refresh tokens on logout" do
      create_member

      post "/api/v1/auth/login", params: login_params
      expect(response).to have_http_status(:ok)

      access_token = response.parsed_body["access_token"]
      refresh_token = response.parsed_body["refresh_token"]

      delete "/api/v1/auth/logout",
             headers: { "Authorization" => "Bearer #{access_token}" },
             params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:no_content)

      # Repeating logout must not cause a server error.
      delete "/api/v1/auth/logout",
             headers: { "Authorization" => "Bearer #{access_token}" },
             params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:unauthorized)

      get "/api/v1/users/1",
          headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:unauthorized)

      post "/api/v1/auth/refresh",
           params: {
             refresh_token: refresh_token,
             subdomain: company.subdomain
           }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "rate limiting" do
    it "blocks login requests after 10 attempts within one minute" do
      10.times do
        post "/api/v1/auth/login", params: login_params
      end

      post "/api/v1/auth/login", params: login_params

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
