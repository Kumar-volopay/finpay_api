



require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  before(:each) do
    Rails.cache.clear
  end

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
      expect(response.parsed_body).to eq(
        "error" => "Invalid invitation"
      )
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
    it "rejects a numeric email without a server error" do
      post "/api/v1/auth/login",
           params: login_params.merge(email: 12345)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an unknown email with invalid credentials" do
      post "/api/v1/auth/login",
           params: login_params.merge(email: "unknown@example.com")

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "error" => "Invalid credentials"
      )
    end
  end

  describe "POST /api/v1/auth/refresh" do
    it "revokes the token family when a rotated refresh token is reused" do
      create_member

      post "/api/v1/auth/login", params: login_params
      expect(response).to have_http_status(:ok)

      first_refresh_token = response.parsed_body["refresh_token"]

      post "/api/v1/auth/refresh",
           params: {
             refresh_token: first_refresh_token,
             subdomain: company.subdomain
           }

      expect(response).to have_http_status(:ok)
      second_refresh_token = response.parsed_body["refresh_token"]

      post "/api/v1/auth/refresh",
           params: {
             refresh_token: first_refresh_token,
             subdomain: company.subdomain
           }

      expect(response).to have_http_status(:unauthorized)

      post "/api/v1/auth/refresh",
           params: {
             refresh_token: second_refresh_token,
             subdomain: company.subdomain
           }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "disabled users" do
    it "rejects refresh tokens and revokes their family" do
      user = create_member

      post "/api/v1/auth/login", params: login_params
      expect(response).to have_http_status(:ok)

      refresh_token = response.parsed_body["refresh_token"]
      digest = Digest::SHA256.hexdigest(refresh_token)

      Apartment::Tenant.switch(company.subdomain) do
        user.update!(disabled_at: Time.current)
      end

      post "/api/v1/auth/refresh",
           params: {
             refresh_token: refresh_token,
             subdomain: company.subdomain
           }

      expect(response).to have_http_status(:unauthorized)

      Apartment::Tenant.switch(company.subdomain) do
        token = RefreshToken.find_by!(token_digest: digest)
        expect(token).to be_revoked
      end
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
