# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Expense performance", type: :request do
  before do
    # Pause Bullet while creating test data.
    Bullet.pause

    begin
      @company = Companies::Provision.call(
        name: "Expense Performance Company",
        subdomain: "expense_performance"
      )

      Apartment::Tenant.switch(@company.subdomain) do
        10.times do |i|
          user = create(
            :user,
            email: "performance#{i}@example.com"
          )

          category = create(:category)

          create(
            :expense,
            user: user,
            category: category,
            title: "Performance expense #{i + 1}"
          )
        end
      end
    ensure
      Bullet.resume
    end
  end

  describe "eager loading associations" do
    it "loads expenses with categories and users without N+1 queries" do
      Apartment::Tenant.switch(@company.subdomain) do
        records = Expense.includes(:category, :user).to_a

        expect(records.length).to eq(10)

        records.each do |expense|
          expect(expense.category).to be_present
          expect(expense.user).to be_present
        end
      end
    end
  end

  describe "Bullet N+1 detection" do
    it "detects N+1 queries when associations are not eager loaded",
       :bullet_n_plus_one_expected do
      ActiveRecord::Base.uncached do
        Apartment::Tenant.switch(@company.subdomain) do
          records = Expense.order(:id).to_a

          records.each do |expense|
            expense.category.name
            expense.user.email
          end
        end
      end

      expect(Bullet.notification?).to be(true)
    end
  end
end
