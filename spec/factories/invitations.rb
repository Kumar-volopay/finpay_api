FactoryBot.define do
  factory :invitation do
    sequence(:email) { |n| "invited#{n}@example.com" }
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    role { 1 }
    association :invited_by, factory: :user
    expires_at { 24.hours.from_now }
    accepted_at { nil }
  end
end
