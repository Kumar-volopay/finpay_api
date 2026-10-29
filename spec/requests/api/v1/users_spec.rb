require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let!(:company) do
    Companies::Provision.call(
      name: "Request Spec Company",
      subdomain: "request_spec_company"
    )
  end

  let!(:other_company) do
    Companies::Provision.call(
      name: "Other Request Spec Company",
      subdomain: "other_request_spec"
    )
  end

  let!(:member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, email: "member@example.com")
    end
  end

  let!(:another_member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, email: "another_member@example.com")
    end
  end

  let!(:other_tenant_member) do
    Apartment::Tenant.switch(other_company.subdomain) do
      create(:user, email: "other_tenant_member@example.com")
    end
  end

  let(:access_token) do
    Authentication::TokenService.encode(
      user: member,
      company_id: company.id
    )
  end

  def get_user(user_id, token)
    get "/api/v1/users/#{user_id}",
        headers: { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /api/v1/users/:id" do
    it "allows a member to access their own record" do
      get_user(member.id, access_token)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["email"]).to eq(member.email)
    end

    it "forbids a member from accessing another member's record" do
      get_user(another_member.id, access_token)

      expect(response).to have_http_status(:forbidden)
    end

    it "does not expose a user from another tenant" do
      current_tenant_max_id = Apartment::Tenant.switch(company.subdomain) do
        User.maximum(:id) || 0
      end

      other_user_id = Apartment::Tenant.switch(other_company.subdomain) do
        loop do
          user = create(:user)
          break user.id if user.id > current_tenant_max_id
        end
      end

      get_user(other_user_id, access_token)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "Unauthorized")
    end

    it "rejects an expired access token" do
      expired_token = JWT.encode(
        {
          sub: member.id,
          jti: SecureRandom.uuid,
          company_id: company.id,
          iat: 30.minutes.ago.to_i,
          exp: 1.minute.ago.to_i
        },
        Rails.application.secret_key_base,
        "HS256"
      )

      get_user(member.id, expired_token)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
