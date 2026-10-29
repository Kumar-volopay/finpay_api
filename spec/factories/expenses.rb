FactoryBot.define do
  factory :expense do
    association :user
    association :category
    title { "Office supplies" }
    amount_cents { 1250 }
    currency { "USD" }
    status { "pending" }
    incurred_on { Date.current }
    notes { "Test expense notes" }
  end
end
