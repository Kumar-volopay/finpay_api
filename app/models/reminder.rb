# frozen_string_literal: true

class Reminder < ApplicationRecord
  belongs_to :expense

  validates :reminder_date, presence: true
  validates :reminder_type, presence: true,
                            inclusion: { in: %w[overdue] }
end
