# frozen_string_literal: true

class IdempotencyService < ApplicationService
  def initialize(expense:, actor:, key:, fingerprint:)
    @expense = expense
    @actor = actor
    @key = key
    @fingerprint = fingerprint
  end

  def call
    return failure("Idempotency key is required", status: 400) if @key.blank?
    return failure("Idempotency key exceeds 255 characters", status: 400) if @key.length > 255
    return failure("Actor is required") if @actor.nil?
    return failure("Request fingerprint is required") if @fingerprint.blank?

    record = IdempotencyKey.create_or_find_by!(
      actor: @actor,
      key: @key
    ) do |new_record|
      new_record.expense = @expense
      new_record.request_fingerprint = @fingerprint
      new_record.expires_at = 24.hours.from_now
    end

    raise ApiErrors::IdempotencyConflict if record.expense_id != @expense.id

    raise ApiErrors::IdempotencyConflict if record.request_fingerprint != @fingerprint

    if record.previously_new_record?
      return success(record, record: record)
    end


    success(
      record,
      replayed: true,
      response_status: record.response_status,
      response_body: record.response_body,
      record: record
    )
  end
end
