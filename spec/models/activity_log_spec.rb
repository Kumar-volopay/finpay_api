
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityLog do
  let(:category) { create(:category) }
  let(:employee) { create(:user, role: :member) }
  let(:admin) { create(:user, role: :admin) }

  let(:expense) do
    create(:expense, user: employee, category: category)
  end

  let(:activity_log) do
    create(
      :activity_log,
      expense: expense,
      actor: admin,
      action: "approve",
      from_state: "pending",
      to_state: "approved"
    )
  end

  describe "associations" do
    it "belongs to an expense" do
      expect(described_class.reflect_on_association(:expense).macro).to eq(:belongs_to)
    end

    it "belongs to an actor" do
      expect(described_class.reflect_on_association(:actor).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires an action" do
      log = build(:activity_log, action: nil)

      expect(log).not_to be_valid
    end

    it "requires a from_state" do
      log = build(:activity_log, from_state: nil)

      expect(log).not_to be_valid
    end

    it "requires a to_state" do
      log = build(:activity_log, to_state: nil)

      expect(log).not_to be_valid
    end
  end

  describe "immutability" do
    it "prevents updating an existing activity log" do
      expect {
        activity_log.update!(action: "reject")
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "prevents deleting an existing activity log" do
      expect {
        activity_log.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
