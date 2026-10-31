require "rails_helper"

RSpec.describe "FinpayAPI application smoke test" do
  it "boots the Rails application successfully" do
    expect(Rails.application).to be_present
    expect(Rails.env.test?).to be(true)
  end
end
