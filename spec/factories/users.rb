FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "member#{n}@example.com" }
    password { "TestPass123!" }
    password_confirmation { "TestPass123!" }
    role { :member }
    jti { SecureRandom.uuid }
  end
end
