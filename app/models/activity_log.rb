# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  belongs_to :expense
  belongs_to :actor, class_name: "User", inverse_of: :activity_logs

  validates :action, inclusion: {
    in: %w[create approve reject reimburse archive]
  }

  validates :from_state, inclusion: {
    in: %w[new pending approved rejected reimbursed archived]
  }

  validates :to_state, inclusion: {
    in: %w[pending approved rejected reimbursed archived]
  }

  def readonly?
    persisted?
  end
end
