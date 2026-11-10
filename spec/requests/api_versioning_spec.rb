require "rails_helper"

RSpec.describe "API versioning", type: :request do
  it "allows the versioned login endpoint" do
    post "/api/v1/auth/login",
         params: {
           email: "missing@example.com",
           password: "wrong-password"
         }

    expect(response).not_to have_http_status(:not_found)
  end

  it "returns 404 for the old unversioned login endpoint" do
    post "/api/auth/login"

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 for the old unversioned expenses endpoint" do
    get "/api/expenses"

    expect(response).to have_http_status(:not_found)
  end
  it "allows the versioned protected endpoint to reach the API" do
    get "/api/v1/protected"

    expect(response).not_to have_http_status(:not_found)
  end

  it "keeps the health check endpoint outside API versioning" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
