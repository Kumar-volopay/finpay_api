# frozen_string_literal: true

class ExpenseSerializer
  include Alba::Resource

  attributes :id, :title, :amount_cents, :currency, :status,
             :incurred_on, :created_at, :updated_at

  attribute :amount do |expense|
    expense.amount_decimal
  end

  attribute :category_id do |expense|
    expense.category_id
  end

  attribute :user_id do |expense|
    expense.user_id
  end
end
