# frozen_string_literal: true

module ApiResponseHelpers
  def expect_standard_error_response(code:, message:)
    body = response.parsed_body

    expect(body.keys).to contain_exactly("error")
    expect(body.fetch("error").keys)
      .to contain_exactly("code", "message", "details", "request_id")
    expect(body.dig("error", "code")).to eq(code)
    expect(body.dig("error", "message")).to eq(message)
    expect(body.dig("error", "request_id")).to be_present

    expect(response.body).not_to match(
      /SELECT\s+.*FROM|INSERT INTO|UPDATE\s+.*SET|PG::|ActiveRecord::|app\/.*\.rb:\d+/i
    )
  end
end

RSpec.configure do |config|
  config.include ApiResponseHelpers, type: :request
end
