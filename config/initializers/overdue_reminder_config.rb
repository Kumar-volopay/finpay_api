# frozen_string_literal: true

overdue_days = ENV.fetch("OVERDUE_EXPENSE_DAYS", "7")

unless overdue_days.match?(/\A\d+\z/) && overdue_days.to_i.positive?
  raise ArgumentError, "OVERDUE_EXPENSE_DAYS must be a positive integer"
end
