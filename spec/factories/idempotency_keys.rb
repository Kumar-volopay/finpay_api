FactoryBot.define do
  factory :idempotency_key do
    association :expense

    sequence(:key) { |n| "idempotency-key-#{n}" }
    request_fingerprint { "test-fingerprint" }
  end
end
