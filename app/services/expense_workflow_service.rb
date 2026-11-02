
# frozen_string_literal: true

class ExpenseWorkflowService < ApplicationService
  ACTIONS = %i[approve reject reimburse].freeze

  def initialize(expense:, actor:, action:, idempotency_key: nil, request_fingerprint: nil)
    @expense = expense
    @actor = actor
    @action = action.to_sym
    @idempotency_key = idempotency_key
    @request_fingerprint = request_fingerprint
  end

  def call
    return failure("Unsupported workflow action") unless ACTIONS.include?(@action)

    if @action == :reimburse
      return failure("Idempotency key is required", status: 400) if @idempotency_key.blank?
      return failure("Request fingerprint is required") if @request_fingerprint.blank?
    end

    @expense.with_lock do
      if @action == :reimburse
        idempotency_result = reserve_idempotency_key

        if !idempotency_result.success?
          idempotency_result
        elsif idempotency_result.replayed?
          success(
            @expense,
            replayed?: true,
            response_status: idempotency_result.response_status,
            response_body: idempotency_result.response_body
          )
        else
          @idempotency_record = idempotency_result.record
          execute_transition
        end
      else
        execute_transition
      end
    end
  rescue AASM::InvalidTransition
    failure("Invalid expense status transition")
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  rescue ActiveRecord::RecordNotUnique
    failure("Idempotency key has already been used", status: 422)
  end

  private

  def execute_transition
    from_state = @expense.status

    perform_transition
    record_actor_and_timestamp

    ActivityLog.create!(
      expense: @expense,
      actor: @actor,
      action: @action,
      from_state: from_state,
      to_state: @expense.status
    )

    response_body = {
      expense_id: @expense.id,
      status: @expense.status
    }

    if @action == :reimburse
      @idempotency_record.update!(
        response_status: 200,
        response_body: response_body
      )
    end

    success(
      @expense,
      response_status: 200,
      response_body: response_body
    )
  end

  def reserve_idempotency_key
    IdempotencyService.call(
      expense: @expense,
      key: @idempotency_key,
      fingerprint: @request_fingerprint
    )
  end

  def perform_transition
    case @action
    when :approve
      @expense.approve!
    when :reject
      @expense.reject!
    when :reimburse
      @expense.reimburse!
    end
  end

  def record_actor_and_timestamp
    timestamp = Time.current

    case @action
    when :approve
      @expense.update!(approved_by: @actor, approved_at: timestamp)
    when :reject
      @expense.update!(rejected_by: @actor, rejected_at: timestamp)
    when :reimburse
      @expense.update!(reimbursed_by: @actor, reimbursed_at: timestamp)
    end
  end
end
