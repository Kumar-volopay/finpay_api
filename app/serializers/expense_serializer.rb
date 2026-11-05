# frozen_string_literal: true

class ExpenseSerializer
  include Alba::Resource

  attributes :id, :reference_number, :title, :notes,
             :amount_cents, :currency, :status, :incurred_on,
             :category_id, :user_id, :approved_by_id, :approved_at,
             :created_at, :updated_at

  attribute :amount do |expense|
    expense.amount_decimal
  end
end
