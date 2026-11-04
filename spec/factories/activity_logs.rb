FactoryBot.define do
  factory :activity_log do
    association :expense
    association :actor, factory: :user

    action { "approve" }
    from_state { "pending" }
    to_state { "approved" }
  end
end
