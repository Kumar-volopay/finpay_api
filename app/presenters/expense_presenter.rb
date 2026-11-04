# frozen_string_literal: true

class ExpensePresenter
  def initialize(expense)
    @expense = expense
  end

  def amount
    return if @expense.amount_cents.nil? || @expense.currency.blank?

    digits = MoneyFormatting.fraction_digits(@expense.currency)
    whole, fraction = @expense.amount_cents.divmod(10**digits)

    return whole.to_s if digits.zero?

    "#{whole}.#{fraction.to_s.rjust(digits, '0')}"
  end
end
