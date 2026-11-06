
require "swagger_helper"

RSpec.describe "Expense Workflow API", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Rswag Workflow Company",
      prefix: "rswag_workflow"
    )
  end

  let(:member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "workflow_member@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: :member
      )
    end
  end

  let(:admin) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "workflow_admin@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!",
        role: :admin
      )
    end
  end

  let(:category) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:category)
    end
  end

  let(:expense) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :expense,
        user: member,
        category: category,
        status: "pending"
      )
    end
  end

  let(:admin_token) do
    post "/api/v1/auth/login",
      params: {
        subdomain: company.subdomain,
        email: admin.email,
        password: "TestPass123!"
      }

    response.parsed_body.fetch("access_token")
  end

  let(:Authorization) { "Bearer #{admin_token}" }
  let(:"Idempotency-Key") { "rswag-workflow-key-001" }

  path "/api/v1/expenses/{id}/approve" do
    parameter name: :id, in: :path, type: :integer, required: true

    post "Approve an expense" do
      tags "Expense Workflow"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: "Idempotency-Key", in: :header,
                type: :string, required: false

      response "200", "expense approved" do
        let(:id) { expense.id }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:Authorization) { nil }
        run_test!
      end

      response "403", "approval not authorized" do
        let(:id) { expense.id }
        let(:member_token) do
          post "/api/v1/auth/login",
            params: {
              subdomain: company.subdomain,
              email: member.email,
              password: "TestPass123!"
            }
          response.parsed_body.fetch("access_token")
        end
        let(:Authorization) { "Bearer #{member_token}" }
        run_test!
      end
    end
  end

  path "/api/v1/expenses/{id}/reject" do
    parameter name: :id, in: :path, type: :integer, required: true

    post "Reject an expense" do
      tags "Expense Workflow"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: :reason, in: :body, schema: {
        type: :object,
        properties: {
          reason: { type: :string, maxLength: 500 }
        },
        required: [ "reason" ]
      }

      response "200", "expense rejected" do
        let(:id) { expense.id }
        let(:reason) { { reason: "Does not meet expense policy" } }
        run_test!
      end

      response "422", "rejection reason required" do
        let(:id) { expense.id }
        let(:reason) { {} }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:reason) { { reason: "Policy violation" } }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/expenses/{id}/reimburse" do
    parameter name: :id, in: :path, type: :integer, required: true

    post "Reimburse an approved expense" do
      tags "Expense Workflow"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: "Idempotency-Key", in: :header, type: :string,
                required: true

      response "200", "expense reimbursed" do
        let(:id) do
          Apartment::Tenant.switch(company.subdomain) do
            expense.update!(status: :approved)
            expense.id
          end
        end
        run_test!
      end

      response "400", "idempotency key required" do
        let(:id) do
          Apartment::Tenant.switch(company.subdomain) do
            expense.update!(status: :approved)
            expense.id
          end
        end
        let(:"Idempotency-Key") { nil }
        run_test!
      end

      response "422", "invalid workflow transition" do
        let(:id) { expense.id }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/expenses/{id}/archive" do
    parameter name: :id, in: :path, type: :integer, required: true

    post "Archive a reimbursed expense" do
      tags "Expense Workflow"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      response "200", "expense archived" do
        let(:id) do
          Apartment::Tenant.switch(company.subdomain) do
            expense.update!(status: :reimbursed)
            expense.id
          end
        end
        run_test!
      end

      response "403", "archive not authorized" do
        let(:id) { expense.id }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
