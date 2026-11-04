# frozen_string_literal: true

class IdempotencyKeyCleanupJob < ApplicationJob
  queue_as :default

  def perform
    IdempotencyKey.where("expires_at <= ?", Time.current).delete_all
  end
end
