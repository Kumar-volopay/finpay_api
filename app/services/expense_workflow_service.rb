# frozen_string_literal: true

class ExpenseWorkflowService < ApplicationService
  ACTIONS = %i[approve reject reimburse archive].freeze

  def initialize(expense:, actor:, action:, idempotency_key: nil, request_fingerprint: nil, metadata: {})
    @expense = expense
    @actor = actor
    @action = action.to_sym
    @idempotency_key = idempotency_key
    @request_fingerprint = request_fingerprint
    @metadata = metadata
  end

  def call
    return failure("Unsupported workflow action") unless ACTIONS.include?(@action)

    if @action == :reimburse && @idempotency_key.blank?
      return failure("Idempotency key is required", status: 400)
    end

    if @idempotency_key.present? && @request_fingerprint.blank?
      return failure("Request fingerprint is required")
    end

    @expense.with_lock do
      process_idempotency
    end
  rescue AASM::InvalidTransition
    failure("Invalid expense status transition")
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.join(", "))
  end

  private

  def process_idempotency
    return execute_transition if @idempotency_key.blank?

    result = reserve_idempotency_key

    return result unless result.success?
    return replay_response(result) if result.replayed?

    @idempotency_record = result.record
    execute_transition
  end

  def replay_response(result)
    success(
      @expense,
      replayed: true,
      response_status: result.response_status,
      response_body: result.response_body
    )
  end

  def execute_transition
    from_state = @expense.status
    record_actor_and_timestamp
    perform_transition

    ActivityLog.create!(
      expense: @expense,
      actor: @actor,
      action: @action,
      from_state: from_state,
      to_state: @expense.status,
      metadata: @metadata.merge(
        idempotency_key: @idempotency_key
      ).compact
    )

    response_body = {
      expense_id: @expense.id,
      status: @expense.status
    }

    if @idempotency_record
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
      actor: @actor,
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
    when :archive
      @expense.archive!
    end
  end

  def record_actor_and_timestamp
    timestamp = Time.current

    case @action
    when :approve
      @expense.assign_attributes(approved_by: @actor, approved_at: timestamp)
    when :reject
      @expense.assign_attributes(rejected_by: @actor, rejected_at: timestamp)
    when :reimburse
      @expense.assign_attributes(reimbursed_by: @actor, reimbursed_at: timestamp)
    end
  end
end
