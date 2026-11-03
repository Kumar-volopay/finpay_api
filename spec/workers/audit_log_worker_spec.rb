# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLogWorker do
  let!(:company) do
    subdomain = tenant_subdomain("audit_worker")
    track_tenant_schema(subdomain)

    Companies::Provision.call(
      name: "Audit Worker Spec Company",
      subdomain: subdomain
    )
  end

  let(:expense) do
    Apartment::Tenant.switch(company.subdomain) do
      user = create(:user)
      category = create(:category)

      create(:expense, user: user, category: category)
    end
  end

  describe "#perform" do
    it "creates an audit log successfully" do
      event_key = "expense:#{expense.id}:created:v1"

      described_class.new.perform(
        company.id,
        expense.id,
        expense.user_id,
        "create",
        "new",
        expense.status,
        event_key
      )

      Apartment::Tenant.switch(company.subdomain) do
        log = ActivityLog.find_by!(event_key: event_key)

        expect(log.expense_id).to eq(expense.id)
        expect(log.actor_id).to eq(expense.user_id)
        expect(log.action).to eq("create")
      end
    end

    it "does not create duplicate audit logs when performed twice" do
      event_key = "expense:#{expense.id}:created:v1"

      2.times do
        described_class.new.perform(
          company.id,
          expense.id,
          expense.user_id,
          "create",
          "new",
          expense.status,
          event_key
        )
      end

      Apartment::Tenant.switch(company.subdomain) do
        expect(ActivityLog.where(event_key: event_key).count).to eq(1)
      end
    end
  end
end
