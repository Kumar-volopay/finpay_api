require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Users Request Spec Company",
      prefix: "users_request"
    )
  end

  let(:member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, role: :member)
    end
  end

  let(:another_member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, role: :member)
    end
  end

  let(:admin) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, role: :admin)
    end
  end

  describe "GET /api/v1/users/:id" do
    it "allows a member to view their own profile" do
      get "/api/v1/users/#{member.id}",
          headers: auth_headers(member, company)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(member.id)
      expect(response.parsed_body.dig("data", "email")).to eq(member.email)
      expect(response.parsed_body.dig("data", "role")).to eq("member")
    end

    it "prevents a member from viewing another member's profile" do
      get "/api/v1/users/#{another_member.id}",
          headers: auth_headers(member, company)

      expect(response).to have_http_status(:not_found)
    end

    it "allows an admin to view another member's profile" do
      get "/api/v1/users/#{another_member.id}",
          headers: auth_headers(admin, company)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(another_member.id)
    end

    it "prevents access to a user belonging to another tenant" do
      other_company = provision_test_tenant(
        name: "Other Users Company",
        prefix: "other_users"
      )

      other_user = Apartment::Tenant.switch(other_company.subdomain) do
        create(:user, role: :member)
        create(:user, role: :member)
      end

      get "/api/v1/users/#{other_user.id}",
          headers: auth_headers(member, company)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects an unauthenticated request" do
      get "/api/v1/users/#{member.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
