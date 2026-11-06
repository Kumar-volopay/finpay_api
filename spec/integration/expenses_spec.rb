require "swagger_helper"

RSpec.describe "Expenses API", type: :request do
  let!(:company) do
    provision_test_tenant(
      name: "Rswag Expenses Company",
      prefix: "rswag_expenses"
    )
  end

  let(:member) do
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :user,
        email: "rswag_expense@example.com",
        password: "TestPass123!",
        password_confirmation: "TestPass123!"
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
      create(:expense, user: member, category: category)
    end
  end

  let(:token) do
    post "/api/v1/auth/login",
      params: {
        subdomain: company.subdomain,
        email: member.email,
        password: "TestPass123!"
      }

    response.parsed_body.fetch("access_token")
  end

  let(:Authorization) { "Bearer #{token}" }

  let(:expense_body) do
    {
      expense: {
        title: "Business travel",
        amount_cents: 2500,
        currency: "USD",
        category_id: category.id,
        incurred_on: Date.current,
        notes: "Business trip"
      }
    }
  end

  path "/api/v1/expenses" do
    get "List expenses" do
      tags "Expenses"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: :category_id, in: :query,
                type: :integer, required: false,
                description: "Filter by category ID",
                minimum: 1

      parameter name: :status, in: :query,
                type: :string, required: false,
                enum: %w[pending approved rejected],
                description: "Filter by expense status"

      parameter name: :from, in: :query,
                type: :string, format: :date, required: false,
                description: "Filter expenses incurred on or after this date"

      parameter name: :to, in: :query,
                type: :string, format: :date, required: false,
                description: "Filter expenses incurred on or before this date"

      parameter name: :page, in: :query,
                type: :integer, required: false,
                minimum: 1, default: 1

      parameter name: :per_page, in: :query,
                type: :integer, required: false,
                minimum: 1, maximum: 100, default: 20

      parameter name: :pagination, in: :query,
                type: :string, required: false,
                enum: %w[offset cursor],
                default: "offset",
                description: "Choose offset or cursor pagination"

      parameter name: :cursor, in: :query,
                type: :string, required: false,
                description: "Cursor returned by the previous cursor-based response"

      response "200", "expenses returned" do
        let(:Authorization) { "Bearer #{token}" }

        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  title: { type: :string },
                  amount_cents: { type: :integer },
                  amount: { type: :number },
                  currency: { type: :string },
                  status: { type: :string },
                  category_id: { type: :integer },
                  user_id: { type: :integer }
                }
              }
            },
            meta: {
              type: :object,
              properties: {
                pagination: {
                  type: :object,
                  properties: {
                    current_page: { type: :integer },
                    per_page: { type: :integer },
                    total_count: { type: :integer },
                    total_pages: { type: :integer },
                    next_cursor: { type: :string, nullable: true }
                  }
                }
              }
            }
          }

        run_test!
      end

      response "401", "authentication required" do
        let(:Authorization) { nil }
        run_test!
      end

      response "422", "invalid filters or pagination" do
        let(:Authorization) { "Bearer #{token}" }
        let(:status) { "invalid-status" }
        run_test!
      end
    end

    post "Create an expense" do
      tags "Expenses"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: :expense_body, in: :body, schema: {
        type: :object,
        properties: {
          expense: {
            type: :object,
            properties: {
              title: { type: :string },
              amount_cents: { type: :integer },
              currency: { type: :string },
              category_id: { type: :integer },
              incurred_on: { type: :string, format: :date },
              notes: { type: :string }
            },
            required: %w[title amount_cents currency category_id incurred_on]
          }
        },
        required: [ "expense" ]
      }

      response "201", "expense created" do
        let(:Authorization) { "Bearer #{token}" }
        run_test!
      end

      response "401", "authentication required" do
        let(:Authorization) { nil }
        run_test!
      end

      response "422", "validation failed" do
        let(:Authorization) { "Bearer #{token}" }
        let(:expense_body) do
          { expense: { title: "", amount_cents: 2500, currency: "USD",
                       category_id: category.id, incurred_on: Date.current } }
        end
        run_test!
      end
    end
  end

  path "/api/v1/expenses/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Show an expense" do
      tags "Expenses"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      response "200", "expense returned" do
        let(:id) { expense.id }
        let(:Authorization) { "Bearer #{token}" }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:Authorization) { nil }
        run_test!
      end

      response "404", "expense not found" do
        let(:id) { 999999 }
        let(:Authorization) { "Bearer #{token}" }
        run_test!
      end
    end

    patch "Update an expense" do
      tags "Expenses"
      consumes "application/json"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      parameter name: :expense_body, in: :body, schema: {
        type: :object,
        properties: {
          expense: {
            type: :object,
            properties: {
              title: { type: :string },
              notes: { type: :string }
            }
          }
        },
        required: [ "expense" ]
      }

      response "200", "expense updated" do
        let(:id) { expense.id }
        let(:Authorization) { "Bearer #{token}" }
        let(:expense_body) { { expense: { title: "Updated expense" } } }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:Authorization) { nil }
        let(:expense_body) { { expense: { title: "Updated expense" } } }
        run_test!
      end

      response "404", "expense not found" do
        let(:id) { 999999 }
        let(:Authorization) { "Bearer #{token}" }
        let(:expense_body) { { expense: { title: "Updated expense" } } }
        run_test!
      end
    end

    delete "Cancel an expense" do
      tags "Expenses"
      produces "application/json"
      security [ { BearerAuth: [] } ]

      response "204", "expense cancelled" do
        let(:id) { expense.id }
        let(:Authorization) { "Bearer #{token}" }
        run_test!
      end

      response "401", "authentication required" do
        let(:id) { expense.id }
        let(:Authorization) { nil }
        run_test!
      end

      response "404", "expense not found" do
        let(:id) { 999999 }
        let(:Authorization) { "Bearer #{token}" }
        run_test!
      end
    end
  end
end
