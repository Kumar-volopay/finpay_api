# frozen_string_literal: true

class ExpenseSerializer
  include Alba::Resource

  attributes :id, :title, :amount_cents, :currency, :status,
             :incurred_on, :category_id, :user_id, :created_at, :updated_at

  attribute :amount do |expense|
    expense.amount_decimal
  end
end
