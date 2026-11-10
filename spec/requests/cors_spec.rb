require "rails_helper"

RSpec.describe "CORS", type: :request do
  let(:allowed_origin) { "http://localhost:3000" }
  let(:disallowed_origin) { "https://untrusted.example" }

  it "allows requests from configured origins" do
    get "/api/v1/protected",
        headers: { "Origin" => allowed_origin }

    expect(response.headers["Access-Control-Allow-Origin"]).to eq(allowed_origin)
  end

  it "does not allow requests from unconfigured origins" do
    get "/api/v1/protected",
        headers: { "Origin" => disallowed_origin }

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end

  it "handles preflight OPTIONS requests from allowed origins" do
    options "/api/v1/protected",
           headers: {
             "Origin" => allowed_origin,
             "Access-Control-Request-Method" => "GET",
             "Access-Control-Request-Headers" => "Authorization,Content-Type"
           }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq(allowed_origin)
    expect(response.headers["Access-Control-Allow-Methods"]).to be_present
    expect(response.headers["Access-Control-Allow-Headers"]).to be_present
  end
end
