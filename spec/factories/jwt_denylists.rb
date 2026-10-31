FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2026-10-28 15:34:41" }
  end
end
