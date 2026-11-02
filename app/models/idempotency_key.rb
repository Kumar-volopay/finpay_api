# frozen_string_literal: true

class IdempotencyKey < ApplicationRecord
  belongs_to :expense

  validates :key, presence: true
  validates :request_fingerprint, presence: true
end
