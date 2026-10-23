FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    sequence(:subdomain) { |n| "company_#{n}" }
  end
end
