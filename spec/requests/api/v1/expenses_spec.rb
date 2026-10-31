
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Expenses", type: :request do
  let!(:company) do
    Companies::Provision.call(
      name: "Expense Request Spec Company",
      subdomain: "expense_request_spec"
    )
  end

  let(:member) { create_user("member@example.com", :member) }
  let(:another_member) { create_user("another@example.com", :member) }
  let(:admin) { create_user("admin@example.com", :admin) }

  let(:member_token) { login(member.email) }
  let(:admin_token) { login(admin.email) }

  let(:headers) do
    { "Authorization" => "Bearer #{member_token}" }
  end

  let(:admin_headers) do
    { "Authorization" => "Bearer #{admin_token}" }
  end

  let(:category) { create_category }

  let!(:own_expense) do
    create_expense(member, category, "My expense")
  end

  let!(:another_expense) do
    create_expense(another_member, category, "Other expense")
  end

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

  def create_expense(user, category, title)
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :expense,
        user: user,
        category: category,
        title: title
      )
    end
  end

  # Count expenses inside the correct tenant schema.
  def tenant_expense_count
    Apartment::Tenant.switch(company.subdomain) do
      Expense.count
    end
  end

  def expense_params
    {
      expense: {
        title: "Travel expense",
        amount_cents: 2500,
        currency: "USD",
        category_id: category.id,
        incurred_on: Date.current,
        notes: "Business travel"
      }
    }
  end

  describe "GET /api/v1/expenses" do
    it "returns only the current member's expenses" do
      get "/api/v1/expenses", headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |expense|
        expense["id"]
      end

      expect(ids).to include(own_expense.id)
      expect(ids).not_to include(another_expense.id)
    end

    it "allows an admin to view all tenant expenses" do
      get "/api/v1/expenses", headers: admin_headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |expense|
        expense["id"]
      end

      expect(ids).to include(own_expense.id, another_expense.id)
    end

    it "rejects an unauthenticated request" do
      get "/api/v1/expenses"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/expenses/:id" do
    it "returns the member's own expense" do
      get "/api/v1/expenses/#{own_expense.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(own_expense.id)
    end

    it "prevents a member from viewing another member's expense" do
      get "/api/v1/expenses/#{another_expense.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "prevents a user from another tenant accessing this tenant's expense" do
      other_company = Companies::Provision.call(
        name: "Other Expense Tenant",
        subdomain: "other_expense_tenant"
      )

      other_user = Apartment::Tenant.switch(other_company.subdomain) do
        create(
          :user,
          email: "other_tenant@example.com",
          password: "TestPass123!",
          password_confirmation: "TestPass123!",
          role: :member
        )
      end

      post "/api/v1/auth/login",
           params: {
             subdomain: other_company.subdomain,
             email: other_user.email,
             password: "TestPass123!"
           }

      expect(response).to have_http_status(:ok)

      other_tenant_token = response.parsed_body.fetch("access_token")

      get "/api/v1/expenses/#{own_expense.id}",
          headers: {
            "Authorization" => "Bearer #{other_tenant_token}"
          }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/expenses" do
    it "creates an expense for the authenticated member" do
      expect {
        post "/api/v1/expenses",
             params: expense_params,
             headers: headers
      }.to change { tenant_expense_count }.by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")
      expect(response.parsed_body["user_id"]).to eq(member.id)
    end

    it "does not allow the client to override user_id or status" do
      post "/api/v1/expenses",
           params: expense_params.deep_merge(
             expense: {
               user_id: another_member.id,
               status: "approved"
             }
           ),
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["user_id"]).to eq(member.id)
      expect(response.parsed_body["status"]).to eq("pending")
    end
  end

  describe "PATCH /api/v1/expenses/:id" do
    it "updates the member's own pending expense" do
      patch "/api/v1/expenses/#{own_expense.id}",
            params: { expense: { title: "Updated title" } },
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("Updated title")
    end

    it "prevents updating another member's expense" do
      patch "/api/v1/expenses/#{another_expense.id}",
            params: { expense: { title: "Changed" } },
            headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "prevents updating an approved expense" do
      Apartment::Tenant.switch(company.subdomain) do
        own_expense.update!(status: :approved)
      end

      patch "/api/v1/expenses/#{own_expense.id}",
            params: { expense: { title: "Changed" } },
            headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/expenses/:id" do
    it "deletes the member's own pending expense" do
      expect {
        delete "/api/v1/expenses/#{own_expense.id}",
               headers: headers
      }.to change { tenant_expense_count }.by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "prevents deleting another member's expense" do
      delete "/api/v1/expenses/#{another_expense.id}",
             headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/expenses filtering" do
    it "filters expenses by category_id" do
      get "/api/v1/expenses",
          params: { category_id: category.id },
          headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |expense|
        expense["id"]
      end

      expect(ids).to include(own_expense.id)
      expect(ids).not_to include(another_expense.id)
    end

    it "filters expenses by status" do
      approved = create_expense(member, category, "Approved expense")

      Apartment::Tenant.switch(company.subdomain) do
        approved.update!(status: :approved)
      end

      get "/api/v1/expenses",
          params: { status: "approved" },
          headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |expense|
        expense["id"]
      end

      expect(ids).to contain_exactly(approved.id)
    end

    it "filters expenses by from date" do
      expense = create_expense(member, category, "Recent expense")

      Apartment::Tenant.switch(company.subdomain) do
        expense.update!(incurred_on: Date.new(2026, 10, 20))
      end

      get "/api/v1/expenses",
          params: { from: "2026-10-20" },
          headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |item|
        item["id"]
      end

      expect(ids).to include(expense.id)
      expect(ids).not_to include(own_expense.id) unless
        own_expense.incurred_on >= Date.new(2026, 10, 20)
    end

    it "filters expenses by to date" do
      expense = create_expense(member, category, "Older expense")

      Apartment::Tenant.switch(company.subdomain) do
        expense.update!(incurred_on: Date.new(2026, 10, 1))
      end

      get "/api/v1/expenses",
          params: { to: "2026-10-01" },
          headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |item|
        item["id"]
      end

      expect(ids).to contain_exactly(expense.id)
    end

    it "filters expenses by a date range" do
      expense = create_expense(member, category, "Date range expense")

      Apartment::Tenant.switch(company.subdomain) do
        expense.update!(incurred_on: Date.new(2026, 10, 15))
      end

      get "/api/v1/expenses",
          params: {
            from: "2026-10-10",
            to: "2026-10-20"
          },
          headers: headers

      expect(response).to have_http_status(:ok)

      ids = response.parsed_body["expenses"].map do |item|
        item["id"]
      end

      expect(ids).to include(expense.id)
    end

    it "returns 422 for an invalid date" do
      get "/api/v1/expenses",
          params: { from: "invalid-date" },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for an unknown status" do
      get "/api/v1/expenses",
          params: { status: "cancelled" },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for an unknown filter parameter" do
      get "/api/v1/expenses",
          params: { unknown_filter: "value" },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Unknown filters")
    end
  end

  describe "GET /api/v1/expenses pagination" do
    it "returns the first page of expenses" do
      24.times do |i|
        create_expense(member, category, "Expense #{i + 1}")
      end

      get "/api/v1/expenses",
          params: { page: 1, per_page: 10 },
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["expenses"].length).to eq(10)
      expect(body["pagination"]["current_page"]).to eq(1)
      expect(body["pagination"]["per_page"]).to eq(10)
      expect(body["pagination"]["total_count"]).to eq(25)
      expect(body["pagination"]["total_pages"]).to eq(3)
    end

    it "returns different records on the second page" do
      24.times do |i|
        create_expense(member, category, "Expense #{i + 1}")
      end

      get "/api/v1/expenses",
          params: { page: 1, per_page: 10 },
          headers: headers

      first_page_ids = response.parsed_body["expenses"].map do |expense|
        expense["id"]
      end

      get "/api/v1/expenses",
          params: { page: 2, per_page: 10 },
          headers: headers

      second_page_ids = response.parsed_body["expenses"].map do |expense|
        expense["id"]
      end

      expect(second_page_ids.length).to eq(10)
      expect(first_page_ids & second_page_ids).to be_empty
    end

    it "uses 20 as the default page size" do
      20.times do |i|
        create_expense(member, category, "Expense #{i + 1}")
      end

      get "/api/v1/expenses", headers: headers

      body = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(body["expenses"].length).to eq(20)
      expect(body["pagination"]["per_page"]).to eq(20)
    end

    it "caps per_page at 100" do
      100.times do |i|
        create_expense(member, category, "Expense #{i + 1}")
      end

      get "/api/v1/expenses",
          params: { per_page: 150 },
          headers: headers

      body = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(body["expenses"].length).to eq(100)
      expect(body["pagination"]["per_page"]).to eq(100)
    end

    it "returns 422 for an invalid page" do
      get "/api/v1/expenses",
          params: { page: 0 },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for an invalid per_page" do
      get "/api/v1/expenses",
          params: { per_page: 0 },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns the first cursor page with a next cursor" do
      24.times do |i|
        create_expense(member, category, "Cursor expense #{i + 1}")
      end

      get "/api/v1/expenses",
          params: { pagination: "cursor", per_page: 10 },
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["expenses"].length).to eq(10)
      expect(body["pagination"]["per_page"]).to eq(10)
      expect(body["pagination"]["next_cursor"]).to be_present
    end

    it "returns the next cursor page without duplicates or gaps" do
      24.times do |i|
        create_expense(member, category, "Cursor expense #{i + 1}")
      end

      expected_ids = Apartment::Tenant.switch(company.subdomain) do
        Expense.where(user_id: member.id)
               .order(created_at: :desc, id: :desc)
               .pluck(:id)
      end

      get "/api/v1/expenses",
          params: { pagination: "cursor", per_page: 10 },
          headers: headers

      expect(response).to have_http_status(:ok)

      first_body = response.parsed_body
      first_page_ids = first_body["expenses"].map { |expense| expense["id"] }
      cursor = first_body.dig("pagination", "next_cursor")

      expect(cursor).to be_present

      get "/api/v1/expenses",
          params: {
            pagination: "cursor",
            per_page: 10,
            cursor: cursor
          },
          headers: headers

      expect(response).to have_http_status(:ok)

      second_body = response.parsed_body
      second_page_ids = second_body["expenses"].map { |expense| expense["id"] }

      expect(second_page_ids.length).to eq(10)
      expect(first_page_ids & second_page_ids).to be_empty
      expect(first_page_ids + second_page_ids).to eq(expected_ids.first(20))
    end

    it "returns 422 for an invalid cursor" do
      get "/api/v1/expenses",
          params: {
            pagination: "cursor",
            cursor: "invalid-cursor"
          },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns nil next_cursor when there are no more records" do
      get "/api/v1/expenses",
          params: {
            pagination: "cursor",
            per_page: 10
          },
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["expenses"].length).to eq(1)
      expect(body["pagination"]["next_cursor"]).to be_nil
    end
  end
end
