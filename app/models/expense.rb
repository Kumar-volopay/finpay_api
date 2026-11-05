# frozen_string_literal: true

class Expense < ApplicationRecord
  include AASM

  before_create :assign_reference_number

  validates :reference_number, uniqueness: true, allow_nil: true

  attr_accessor :audit_company_id

  after_create_commit :enqueue_creation_audit

  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true
  belongs_to :reimbursed_by, class_name: "User", optional: true
  belongs_to :category

  has_many :receipts, dependent: :destroy, inverse_of: :expense
  has_many :reminders, dependent: :destroy
  has_many :activity_logs, dependent: :restrict_with_error

  after_create :create_creation_activity_log
  has_many :idempotency_keys, dependent: :restrict_with_error

  encrypts :notes

  aasm column: :status,
       whiny_transitions: true,
       whiny_persistence: true do
    state :pending, initial: true
    state :approved, :rejected, :reimbursed, :archived, :cancelled

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
  event :cancel do
    transitions from: %i[pending approved rejected reimbursed archived],
                to: :cancelled
  end
  end

  validates :status,
            inclusion: { in: %w[pending approved rejected reimbursed archived cancelled] }
  validates :title, presence: true, length: { maximum: 255 }
  validates :amount_cents,
            numericality: { only_integer: true, greater_than: 0 }
  validates :currency,
            format: { with: /\A[A-Z]{3}\z/ }
  validates :incurred_on, presence: true

  scope :for_user, ->(user_id) { where(user_id: user_id) }


  private

  def create_creation_activity_log
    ActivityLog.create!(
      expense: self,
      actor: user,
      action: "create",
      from_state: "new",
      to_state: status
    )
  end

  def amount_decimal
    return if amount_cents.nil? || currency.blank?

    digits = MoneyFormatting.fraction_digits(currency)
    whole, fraction = amount_cents.divmod(10**digits)

    return whole.to_s if digits.zero?

    "#{whole}.#{fraction.to_s.rjust(digits, '0')}"
  end

  private

  def assign_reference_number
    return if reference_number.present?

    self.id ||= self.class.connection.select_value(
      "SELECT nextval(pg_get_serial_sequence('expenses', 'id')::regclass)"
    )

    self.reference_number = "EXP-#{id}"
  end

  def enqueue_creation_audit
    return unless audit_company_id

    AuditLogWorker.perform_async(
      audit_company_id,
      id,
      user_id,
      "expense:#{id}:created:v1"
    )
  end
end
