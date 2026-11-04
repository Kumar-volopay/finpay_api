# frozen_string_literal: true

class IdempotencyKey < ApplicationRecord
  belongs_to :expense
  belongs_to :actor, class_name: "User"

  validates :key, presence: true, length: { maximum: 255 }
  validates :request_fingerprint, presence: true
end
