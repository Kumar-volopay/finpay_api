
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
          raise ApiErrors::InvalidRequest, "Invalid pagination mode"
        end

        if pagination_mode == "cursor" || params[:cursor].present?
          render_cursor_page(expenses, per_page)
        else
          render_offset_page(expenses, per_page)
        end
      end
      def show
        expense = policy_scope(Expense).find(params[:id])
        authorize expense

        render_success(
          data: ExpenseSerializer.new(expense).to_h
        )
      end

      def create
        expense = Expense.new(expense_params)
        expense.user = @current_user
        expense.status = :pending
        expense.audit_company_id = @current_company.id

        authorize expense

        expense.save!

        render_success(
          data: ExpenseSerializer.new(expense).to_h,
          status: :created
        )
      end

      def update
        expense = policy_scope(Expense).find(params[:id])
        authorize expense

        expense.update!(expense_params)

        render_success(
          data: ExpenseSerializer.new(expense).to_h
        )
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
        reason = params[:reason].to_s.strip if params[:reason].present?

        if action == :reject && reason.blank?
          raise ApiErrors::InvalidRequest, "Rejection reason is required"
        end

        if reason && reason.length > 500
          raise ApiErrors::InvalidRequest, "Reason must not exceed 500 characters"
        end

        expense = policy_scope(Expense).find(params[:id])
        authorize expense, "#{action}?".to_sym

        idempotency_key = request.headers["Idempotency-Key"]

        if idempotency_key.present? &&
           (idempotency_key.length > 255 ||
            !idempotency_key.match?(/\A[A-Za-z0-9._:-]+\z/))
          return render_error(
  code: "invalid_idempotency_key",
  message: "Invalid Idempotency-Key",
  status: :bad_request
)
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
            reason: reason
          }.compact
        )

        if result.success?
          response.set_header("Idempotent-Replayed", "true") if result.replayed?

          render_success(
            data: result.response_body,
            status: result.response_status || :ok
          )
        else
          render_error(
            code: result.error_code || "workflow_error",
            message: result.error,
            status: result.response_status || :unprocessable_content
          )
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

        serialized_expenses = ExpenseSerializer.new(page_records).to_h

        render_success(
          data: serialized_expenses,
          meta: {
            pagination: {
              per_page: per_page,
              next_cursor: next_cursor
            }
          }
       )
      end

      def render_offset_page(expenses, per_page)
        page = pagination_page

        paginated_expenses = expenses
          .order(created_at: :desc, id: :desc)
          .page(page)
          .per(per_page)

        serialized_expenses = ExpenseSerializer.new(paginated_expenses).to_h

        render_success(
          data: serialized_expenses,
          meta: {
            pagination: {
              current_page: paginated_expenses.current_page,
              per_page: paginated_expenses.limit_value,
              total_count: paginated_expenses.total_count,
              total_pages: paginated_expenses.total_pages
            }
          }
        )
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
          raise ApiErrors::InvalidRequest,
                "Unknown filters: #{unknown_filters.join(', ')}"
        end

        params.permit(*allowed_filters)
      end

      def pagination_page
        value = params.fetch(:page, 1).to_s

        unless value.match?(/\A[1-9]\d*\z/)
          raise ApiErrors::InvalidRequest, "Invalid page"
        end

        value.to_i
      end

      def pagination_per_page
        value = params.fetch(:per_page, 20).to_s

        unless value.match?(/\A[1-9]\d*\z/)
          raise ApiErrors::InvalidRequest, "Invalid per_page"
        end

        [ value.to_i, 100 ].min
      end
    end
  end
end
