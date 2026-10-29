# frozen_string_literal: true

class Receipt < ApplicationRecord
  belongs_to :expense

  encrypts :ocr_text

  enum :ocr_status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, validate: true

  validates :storage_key, presence: true
  validates :byte_size,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
end
