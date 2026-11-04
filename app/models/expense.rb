# frozen_string_literal: true

class Expense < ApplicationRecord
  include AASM
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true
  belongs_to :reimbursed_by, class_name: "User", optional: true
  belongs_to :category
  has_many :receipts, dependent: :destroy, inverse_of: :expense
  has_many :activity_logs, dependent: :restrict_with_error
  has_many :idempotency_keys, dependent: :restrict_with_error

  encrypts :notes

  aasm column: :status,
       whiny_transitions: true,
       whiny_persistence: true do
    state :pending, initial: true
    state :approved, :rejected, :reimbursed, :archived

    event :approve do
      transitions from: :pending, to: :approved
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end

    event :reimburse do
      transitions from: :approved, to: :reimbursed
    end

    event :archive do
      transitions from: :reimbursed, to: :archived
    end
  end

  validates :status,
            inclusion: { in: %w[pending approved rejected reimbursed archived] }

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
