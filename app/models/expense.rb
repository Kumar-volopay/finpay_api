# frozen_string_literal: true

class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :receipts, dependent: :destroy, inverse_of: :expense

  encrypts :notes

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }, validate: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :amount_cents,
            numericality: { only_integer: true, greater_than: 0 }
  validates :currency,
            format: { with: /\A[A-Z]{3}\z/ }
  validates :incurred_on, presence: true

  scope :for_user, ->(user_id) { where(user_id: user_id) }

  def amount_decimal
    return if amount_cents.nil? || currency.blank?

    digits = MoneyFormatting.fraction_digits(currency)
    whole, fraction = amount_cents.divmod(10**digits)

    return whole.to_s if digits.zero?

    "#{whole}.#{fraction.to_s.rjust(digits, '0')}"
  end
end
