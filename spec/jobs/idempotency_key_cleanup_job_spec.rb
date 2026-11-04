# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdempotencyKeyCleanupJob, type: :job do
  describe "#perform" do
    let(:actor) { create(:user) }
    let(:expense) { create(:expense, user: actor) }

    def create_idempotency_key(actor, expense, expires_at)
      IdempotencyKey.create!(
        key: SecureRandom.uuid,
        actor: actor,
        expense: expense,
        request_fingerprint: SecureRandom.hex(32),
        expires_at: expires_at
      )
    end

    it "deletes expired keys" do
      expired_key = create_idempotency_key(actor, expense, 1.hour.ago)

      described_class.perform_now

      expect(IdempotencyKey.exists?(expired_key.id)).to be(false)
    end

    it "preserves unexpired keys" do
      active_key = create_idempotency_key(actor, expense, 1.hour.from_now)

      described_class.perform_now

      expect(IdempotencyKey.exists?(active_key.id)).to be(true)
    end

    it "preserves keys without an expiry" do
      permanent_key = create_idempotency_key(actor, expense, nil)

      described_class.perform_now

      expect(IdempotencyKey.exists?(permanent_key.id)).to be(true)
    end
  end
end
