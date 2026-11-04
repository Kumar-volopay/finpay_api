FactoryBot.define do
  factory :refresh_token do
    user_id { "" }
    token_digest { "MyString" }
    expires_at { "2026-10-28 16:38:15" }
    revoked_at { "2026-10-28 16:38:15" }
  end
end
