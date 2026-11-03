
# frozen_string_literal: true

module Api
  module V1
    class ExpensesController < ApplicationController
      include TenantLoader

      def index
        expenses = policy_scope(Expense)
        authorize Expense

        expenses = ExpenseFilter.new(expenses, filter_params).call

        per_page = pagination_per_page
        pagination_mode = params.fetch(:pagination, "offset").to_s

        unless %w[offset cursor].include?(pagination_mode)
          raise ArgumentError, "Invalid pagination mode"
        end

        if pagination_mode == "cursor" || params[:cursor].present?
          render_cursor_page(expenses, per_page)
        else
          render_offset_page(expenses, per_page)
        end
      rescue ArgumentError => e
        render json: { error: e.message },
               status: :unprocessable_entity
      end

      def show
        expense = policy_scope(Expense).find(params[:id])
        authorize expense

        render json: ExpenseSerializer.new(expense).serialize,
               status: :ok
      end

      def create
        expense = Expense.new(expense_params)
        expense.user = @current_user
        expense.status = :pending
        expense.audit_company_id = @current_company.id

        authorize expense

        if expense.save
          render json: ExpenseSerializer.new(expense).serialize,
                 status: :created
        else
          render json: { errors: expense.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def update
        expense = policy_scope(Expense).find(params[:id])
        authorize expense

        if expense.update(expense_params)
          render json: ExpenseSerializer.new(expense).serialize,
                 status: :ok
        else
          render json: { errors: expense.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        expense = policy_scope(Expense).find(params[:id])
        authorize expense

        expense.destroy!

        head :no_content
      end

      def approve
        process_workflow(:approve)
      end

      def reject
        process_workflow(:reject)
      end

      def reimburse
        process_workflow(:reimburse)
      end

      def archive
        process_workflow(:archive)
      end

      private
      def process_workflow(action)
        expense = policy_scope(Expense).find(params[:id])
        authorize expense, "#{action}?".to_sym

        idempotency_key = request.headers["Idempotency-Key"]

        if idempotency_key.present? &&
           (idempotency_key.length > 255 ||
            !idempotency_key.match?(/\A[A-Za-z0-9._:-]+\z/))
          return render json: { error: "Invalid Idempotency-Key" },
                        status: :bad_request
        end

        fingerprint_data = {
          action: action,
          expense_id: expense.id,
          actor_id: @current_user.id,
          params: canonicalize(params.except(:controller, :action, :id).to_unsafe_h)
        }

        fingerprint = Digest::SHA256.hexdigest(fingerprint_data.to_json)

        result = ExpenseWorkflowService.call(
          expense: expense,
          actor: @current_user,
          company_id: @current_company.id,
          action: action,
          idempotency_key: idempotency_key,
          request_fingerprint: fingerprint,
          metadata: {
            request_id: request.request_id,
            ip_address: request.remote_ip,
            reason: params[:reason]
          }.compact
        )

        if result.success?
          response.set_header("Idempotent-Replayed", "true") if result.replayed?

          render json: result.response_body,
                 status: result.response_status || :ok
        else
          render json: { error: result.error },
                 status: result.response_status || :unprocessable_entity
        end
      end

      def canonicalize(value)
        case value
        when Hash
          value.sort_by { |key, _| key.to_s }.to_h do |key, item|
            [ key, canonicalize(item) ]
          end
        when Array
          value.map { |item| canonicalize(item) }
        else
          value
        end
      end

      def render_cursor_page(expenses, per_page)
        ordered_expenses = expenses
        .order(created_at: :desc, id: :desc)

        cursor_expenses = if params[:cursor].present?
                            ExpenseCursor.apply(
                              ordered_expenses,
                              params[:cursor]
                            )
        else
                            ordered_expenses
        end

        records = cursor_expenses.limit(per_page + 1).to_a

        has_more = records.length > per_page
        page_records = records.first(per_page)

        next_cursor = if has_more
                        ExpenseCursor.encode(page_records.last)
        end

        serialized_expenses = JSON.parse(
          ExpenseSerializer.new(page_records).serialize
        )

        render json: {
          expenses: serialized_expenses,
          pagination: {
            per_page: per_page,
            next_cursor: next_cursor
          }
        }, status: :ok
      end

      def render_offset_page(expenses, per_page)
        page = pagination_page

        paginated_expenses = expenses
          .order(created_at: :desc, id: :desc)
          .page(page)
          .per(per_page)

        serialized_expenses = JSON.parse(
          ExpenseSerializer.new(paginated_expenses).serialize
        )

        render json: {
          expenses: serialized_expenses,
          pagination: {
            current_page: paginated_expenses.current_page,
            per_page: paginated_expenses.limit_value,
            total_count: paginated_expenses.total_count,
            total_pages: paginated_expenses.total_pages
          }
        }, status: :ok
      end

      def expense_params
        params.require(:expense).permit(
          :title,
          :amount_cents,
          :currency,
          :category_id,
          :incurred_on,
          :notes
        )
      end

      def filter_params
        allowed_filters = ExpenseFilter::ALLOWED_FILTERS
        allowed_query_params = allowed_filters + %w[
          page per_page cursor pagination
        ]

        unknown_filters = request.query_parameters.keys - allowed_query_params

        if unknown_filters.any?
          raise ArgumentError,
                "Unknown filters: #{unknown_filters.join(', ')}"
        end

        params.permit(*allowed_filters)
      end

      def pagination_page
        value = params.fetch(:page, 1).to_s

        unless value.match?(/\A[1-9]\d*\z/)
          raise ArgumentError, "Invalid page"
        end

        value.to_i
      end

      def pagination_per_page
        value = params.fetch(:per_page, 20).to_s

        unless value.match?(/\A[1-9]\d*\z/)
          raise ArgumentError, "Invalid per_page"
        end

        [ value.to_i, 100 ].min
      end
    end
  end
end
