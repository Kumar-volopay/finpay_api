# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category do
  subject(:category) { build(:category) }

  it "is valid with valid attributes" do
    expect(category).to be_valid
  end

  it "has many expenses" do
    association = described_class.reflect_on_association(:expenses)
    expect(association.macro).to eq(:has_many)
  end

  it "requires a name" do
    category.name = nil
    expect(category).not_to be_valid
  end

  it "rejects a duplicate name" do
    create(:category, name: "Food")

    duplicate = build(:category, name: "Food")

    expect(duplicate).not_to be_valid
  end
end
