require "rails_helper"
require Rails.root.join(
  "db/migrate/20261104121606_backfill_expense_reference_numbers"
)

RSpec.describe BackfillExpenseReferenceNumbers do
  def create_tenant_with_expenses(subdomain:, count:)
    track_tenant_schema(subdomain)

    Companies::Provision.call(
      name: "Migration Test #{subdomain}",
      subdomain: subdomain
    )

    Apartment::Tenant.switch(subdomain) do
      connection = ActiveRecord::Base.connection

      connection.remove_check_constraint(
        :expenses,
        name: "expenses_reference_number_not_null"
      )

      user = FactoryBot.create(:user)
      category = FactoryBot.create(:category)

      expenses = FactoryBot.create_list(
        :expense,
        count,
        user: user,
        category: category
      )

      Expense.where(id: expenses.map(&:id))
             .update_all(reference_number: nil)

      expenses.map(&:id)
    end
  end

  it "backfills different data volumes across two tenant schemas" do
    small_tenant = tenant_subdomain("migration_small")
    large_tenant = tenant_subdomain("migration_large")

    small_ids = create_tenant_with_expenses(
      subdomain: small_tenant,
      count: 3
    )

    large_ids = create_tenant_with_expenses(
      subdomain: large_tenant,
      count: 7
    )

    [ small_tenant, large_tenant ].each do |subdomain|
      Apartment::Tenant.switch(subdomain) do
        described_class.new.up
      end
    end

    {
      small_tenant => small_ids,
      large_tenant => large_ids
    }.each do |subdomain, expected_ids|
      Apartment::Tenant.switch(subdomain) do
        references = Expense.order(:id).pluck(:id, :reference_number)

        expect(references.size).to eq(expected_ids.size)

        references.each do |id, reference_number|
          expect(reference_number).to eq("EXP-#{id}")
        end
      end
    end
  end
end
