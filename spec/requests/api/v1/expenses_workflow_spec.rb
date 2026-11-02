
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Expenses workflow", type: :request do
  let!(:company) do
    Companies::Provision.call(
      name: "Expense Workflow Request Spec Company",
      subdomain: "expense_workflow_request_spec"
    )
  end

  let(:member) { create_user("workflow_member@example.com", :member) }
  let(:another_member) { create_user("workflow_another@example.com", :member) }
  let(:admin) { create_user("workflow_admin@example.com", :admin) }

  let(:member_headers) do
    { "Authorization" => "Bearer #{login(member.email)}" }
  end

  let(:admin_headers) do
    { "Authorization" => "Bearer #{login(admin.email)}" }
  end

  let(:category) { create_category }

  def create_user(email, role)
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: email,
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: role
      )
    end
  end

  def login(email)
    post "/api/v1/auth/login",
         params: {
           subdomain: company.subdomain,
           email: email,
           password: "TestPass123!"
         }

    expect(response).to have_http_status(:ok)
    response.parsed_body.fetch("access_token")
  end

  def create_category
    Apartment::Tenant.switch(company.subdomain) do
      create(:category)
    end
  end

  def create_expense(user, category, title, status: :pending)
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :expense,
        user: user,
        category: category,
        title: title,
        status: status
      )
    end
  end

  def tenant_activity_log_count(expense)
    Apartment::Tenant.switch(company.subdomain) do
      ActivityLog.where(expense_id: expense.id).count
    end
  end

  describe "POST /api/v1/expenses/:id/approve" do
    it "allows an admin to approve another member's expense" do
      expense = create_expense(member, category, "Approval expense")

      post "/api/v1/expenses/#{expense.id}/approve",
           headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("approved")

      Apartment::Tenant.switch(company.subdomain) do
        expect(expense.reload.approved_by_id).to eq(admin.id)
        expect(expense.approved_at).to be_present
      end

      expect(tenant_activity_log_count(expense)).to eq(1)
    end

    it "prevents an admin from approving their own expense" do
      expense = create_expense(admin, category, "Admin own expense")

      post "/api/v1/expenses/#{expense.id}/approve",
           headers: admin_headers

      expect(response).to have_http_status(:forbidden)

      Apartment::Tenant.switch(company.subdomain) do
        expect(expense.reload).to be_pending
      end
    end

    it "prevents a member from approving an expense" do
      expense = create_expense(member, category, "Member expense")

      post "/api/v1/expenses/#{expense.id}/approve",
           headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/expenses/:id/reject" do
    it "allows an admin to reject a pending expense" do
      expense = create_expense(member, category, "Rejection expense")

      post "/api/v1/expenses/#{expense.id}/reject",
           headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("rejected")

      Apartment::Tenant.switch(company.subdomain) do
        expect(expense.reload.rejected_by_id).to eq(admin.id)
        expect(expense.rejected_at).to be_present
      end

      expect(tenant_activity_log_count(expense)).to eq(1)
    end
  end

  describe "POST /api/v1/expenses/:id/reimburse" do
    it "allows an admin to reimburse an approved expense" do
      expense = create_expense(
        member,
        category,
        "Reimbursement expense",
        status: :approved
      )

      post "/api/v1/expenses/#{expense.id}/reimburse",
           headers: admin_headers.merge("Idempotency-Key" => "workflow-reimburse-001")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("reimbursed")

      Apartment::Tenant.switch(company.subdomain) do
        expect(expense.reload.reimbursed_by_id).to eq(admin.id)
        expect(expense.reimbursed_at).to be_present
      end

      expect(tenant_activity_log_count(expense)).to eq(1)
    end

    it "returns the original response when the same request is replayed" do
      expense = create_expense(
        member,
        category,
        "Replay reimbursement",
        status: :approved
      )

      headers = admin_headers.merge(
        "Idempotency-Key" => "workflow-reimburse-002"
      )

      post "/api/v1/expenses/#{expense.id}/reimburse",
           headers: headers

      first_response = response.parsed_body

      post "/api/v1/expenses/#{expense.id}/reimburse",
           headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(first_response)
      expect(tenant_activity_log_count(expense)).to eq(1)
    end


    it "returns 422 when the same key is used for another expense" do
      first_expense = create_expense(
        member, category, "First reimbursement", status: :approved
      )
      second_expense = create_expense(
        member, category, "Second reimbursement", status: :approved
      )

      headers = admin_headers.merge("Idempotency-Key" => "workflow-conflict-001")

      post "/api/v1/expenses/#{first_expense.id}/reimburse",
           headers: headers

      expect(response).to have_http_status(:ok)

      post "/api/v1/expenses/#{second_expense.id}/reimburse",
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)

      Apartment::Tenant.switch(company.subdomain) do
        expect(second_expense.reload).to be_approved
        expect(ActivityLog.where(expense: second_expense)).to be_empty
      end
    end

    it "returns 422 when the same key is reused with a different request" do
      expense = create_expense(
        member, category, "Different payload reimbursement", status: :approved
      )

      headers = admin_headers.merge("Idempotency-Key" => "workflow-conflict-002")

      post "/api/v1/expenses/#{expense.id}/reimburse",
           headers: headers,
           params: { notes: "First request" }

      expect(response).to have_http_status(:ok)

      post "/api/v1/expenses/#{expense.id}/reimburse",
           headers: headers,
           params: { notes: "Different request" }

      expect(response).to have_http_status(:unprocessable_content)

      Apartment::Tenant.switch(company.subdomain) do
        expect(expense.reload).to be_reimbursed
        expect(ActivityLog.where(expense: expense).count).to eq(1)
      end
    end


    it "returns 400 when the idempotency key is missing" do
      expense = create_expense(
        member,
        category,
        "Missing key reimbursement",
        status: :approved
      )

      post "/api/v1/expenses/#{expense.id}/reimburse",
           headers: admin_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq(
        "Idempotency key is required"
      )
    end
  end

  describe "authentication" do
    it "rejects an unauthenticated approval request" do
      expense = create_expense(member, category, "Unauthenticated expense")

      post "/api/v1/expenses/#{expense.id}/approve"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "tenant isolation" do
    it "prevents a member from accessing another member's expense" do
      expense = create_expense(
        another_member,
        category,
        "Another member expense"
      )

      post "/api/v1/expenses/#{expense.id}/approve",
           headers: member_headers

      expect(response).to have_http_status(:not_found)
    end
  end

    it "prevents an admin from another tenant approving an expense" do
      other_subdomain = tenant_subdomain("workflow_other")
      track_tenant_schema(other_subdomain)

      other_company = Companies::Provision.call(
        name: "Another Workflow Company",
        subdomain: other_subdomain
      )

      other_expense = Apartment::Tenant.switch(other_company.subdomain) do
        other_user = create(
          :user,
          role: :member,
          password: "TestPass123!",
          password_confirmation: "TestPass123!"
        )

        create(
          :expense,
          user: other_user,
          category: create(:category),
          status: :pending
        )
      end

      post "/api/v1/expenses/#{other_expense.id}/approve",
           headers: admin_headers

      expect(response).to have_http_status(:not_found)

      Apartment::Tenant.switch(other_company.subdomain) do
        expect(other_expense.reload).to be_pending
        expect(ActivityLog.where(expense: other_expense)).to be_empty
      end
    end
end
