# frozen_string_literal: true

require "rails_helper"

RSpec.describe OverdueReminderWorker do
  let!(:company) do
    subdomain = tenant_subdomain("reminder_worker")
    track_tenant_schema(subdomain)

    Companies::Provision.call(
      name: "Reminder Worker Spec Company",
      subdomain: subdomain
    )
  end

  def create_expense_with_status(status:, incurred_on:)
    Apartment::Tenant.switch(company.subdomain) do
      user = create(:user)
      category = create(:category)

      create(
        :expense,
        user: user,
        category: category,
        status: status,
        incurred_on: incurred_on
      )
    end
  end

  describe "#perform" do
    it "creates reminders only for overdue pending expenses" do
      overdue = create_expense_with_status(
        status: :pending,
        incurred_on: 8.days.ago.to_date
      )

      create_expense_with_status(
        status: :pending,
        incurred_on: Date.current
      )

      create_expense_with_status(
        status: :approved,
        incurred_on: 10.days.ago.to_date
      )

      described_class.new.perform(company.id)

      Apartment::Tenant.switch(company.subdomain) do
        expect(Reminder.pluck(:expense_id)).to contain_exactly(overdue.id)
      end
    end

    it "does not create duplicate reminders when executed twice" do
      overdue = create_expense_with_status(
        status: :pending,
        incurred_on: 8.days.ago.to_date
      )

      2.times { described_class.new.perform(company.id) }

      Apartment::Tenant.switch(company.subdomain) do
        expect(Reminder.where(expense_id: overdue.id).count).to eq(1)
      end
    end


    it "does not affect reminders in another tenant" do
      other_subdomain = tenant_subdomain("reminder_other")
      track_tenant_schema(other_subdomain)

      other_company = Companies::Provision.call(
        name: "Other Reminder Company",
        subdomain: other_subdomain
      )

      first_expense = create_expense_with_status(
        status: :pending,
        incurred_on: 8.days.ago.to_date
      )

      other_expense = Apartment::Tenant.switch(other_company.subdomain) do
        user = create(:user)
        category = create(:category)

        create(
          :expense,
          user: user,
          category: category,
          status: :pending,
          incurred_on: 8.days.ago.to_date
        )
      end

      described_class.new.perform(company.id)

      Apartment::Tenant.switch(company.subdomain) do
        expect(Reminder.pluck(:expense_id)).to contain_exactly(first_expense.id)
      end

      Apartment::Tenant.switch(other_company.subdomain) do
        expect(Reminder.where(expense_id: other_expense.id)).to be_empty
      end
    end

    it "raises an error for a missing company" do
      expect {
        described_class.new.perform(-1)
      }.to raise_error(
        ActiveRecord::RecordNotFound,
        "Company not found: -1"
      )
    end
  end
end
