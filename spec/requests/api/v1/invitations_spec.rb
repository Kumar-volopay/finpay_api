require "rails_helper"

RSpec.describe "Api::V1::Invitations", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Invitation Request Spec Company",
      prefix: "invitation_request"
    )
  end

  let(:admin) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, role: :admin)
    end
  end

  let(:member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, role: :member)
    end
  end

  describe "POST /api/v1/invitations" do
    it "allows an admin to create an invitation" do
      post "/api/v1/invitations",
           params: { email: "newmember@example.com" },
           headers: auth_headers(admin, company)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("invitation", "email"))
        .to eq("newmember@example.com")
      expect(response.parsed_body["invitation_token"]).to be_present
    end

    it "denies a member from creating an invitation" do
      post "/api/v1/invitations",
           params: { email: "newmember@example.com" },
           headers: auth_headers(member, company)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects an unauthenticated request" do
      post "/api/v1/invitations",
           params: { email: "newmember@example.com" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 for an invalid email address" do
      post "/api/v1/invitations",
           params: { email: "invalid-email" },
           headers: auth_headers(admin, company)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code"))
        .to eq("validation_error")
      expect(response.parsed_body.dig("error", "details"))
        .to include(hash_including("field" => "email"))
    end

    it "stores only the token digest in the database" do
      post "/api/v1/invitations",
           params: { email: "secure@example.com" },
           headers: auth_headers(admin, company)

      expect(response).to have_http_status(:created)

      raw_token = response.parsed_body.fetch("invitation_token")
      digest = Digest::SHA256.hexdigest(raw_token)

      stored_invitation = Apartment::Tenant.switch(company.subdomain) do
        Invitation.find_by!(email: "secure@example.com")
      end

      expect(stored_invitation.token_digest).to eq(digest)
      expect(stored_invitation.token_digest).not_to eq(raw_token)
    end
  end
end
