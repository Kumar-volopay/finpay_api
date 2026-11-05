# frozen_string_literal: true

require "rails_helper"
require Rails.root.join(
  "db/migrate/20261104121606_backfill_expense_reference_numbers"
)

RSpec.describe BackfillExpenseReferenceNumbers do
  def create_tenant_with_expenses(subdomain:, count:)
    provision_test_tenant(
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


  def create_tenant_with_many_expenses(subdomain:, count:)
    provision_test_tenant(
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
      now = Time.current

      records = Array.new(count) do
        {
          user_id: user.id,
          category_id: category.id,
          title: "Bulk migration expense",
          amount_cents: 1250,
          currency: "USD",
          status: "pending",
          incurred_on: Date.current,
          notes: "Migration test",
          created_at: now,
          updated_at: now
        }
      end

      result = Expense.insert_all!(records, returning: %w[id])
      result.rows.flatten
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

  it "preserves existing reference numbers and is safe to rerun" do
    subdomain = tenant_subdomain("migration_rerun")
    expense_ids = create_tenant_with_expenses(
      subdomain: subdomain,
      count: 3
    )

    Apartment::Tenant.switch(subdomain) do
      Expense.where(id: expense_ids.first).update_all(
        reference_number: "CUSTOM-REFERENCE"
      )

      described_class.new.up
      described_class.new.up

      expect(
        Expense.find(expense_ids.first).reference_number
      ).to eq("CUSTOM-REFERENCE")

      expense_ids.drop(1).each do |id|
        expect(Expense.find(id).reference_number).to eq("EXP-#{id}")
      end
    end
  end

  it "clears generated reference numbers when rolled back" do
    subdomain = tenant_subdomain("migration_rollback")
    expense_ids = create_tenant_with_expenses(
      subdomain: subdomain,
      count: 3
    )

    Apartment::Tenant.switch(subdomain) do
      Expense.where(id: expense_ids.first).update_all(
        reference_number: "CUSTOM-REFERENCE"
      )

      migration = described_class.new
      migration.up
      migration.down

      expect(
        Expense.find(expense_ids.first).reference_number
      ).to eq("CUSTOM-REFERENCE")

      expense_ids.drop(1).each do |id|
        expect(Expense.find(id).reference_number).to be_nil
      end
    end
  end

  it "backfills expenses across multiple batches" do
    subdomain = tenant_subdomain("migration_batches")

    expense_ids = create_tenant_with_many_expenses(
      subdomain: subdomain,
      count: 1_005
    )

    Apartment::Tenant.switch(subdomain) do
      described_class.new.up

      references = Expense.order(:id).pluck(:id, :reference_number)

      expect(references.size).to eq(1_005)

      references.each do |id, reference_number|
        expect(reference_number).to eq("EXP-#{id}")
      end

      expect(expense_ids).to match_array(references.map(&:first))
    end
  end
end
