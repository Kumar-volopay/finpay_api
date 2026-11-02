# frozen_string_literal: true

class IdempotencyService < ApplicationService
  def initialize(expense:, key:, fingerprint:)
    @expense = expense
    @key = key
    @fingerprint = fingerprint
  end

  def call
    return failure("Idempotency key is required", status: 400) if @key.blank?

    return failure("Request fingerprint is required") if @fingerprint.blank?

    record = IdempotencyKey.create_or_find_by!(key: @key) do |new_record|
      new_record.expense = @expense
      new_record.request_fingerprint = @fingerprint
    end

    return failure("Idempotency key already used for another expense") if
      record.expense_id != @expense.id

    return failure("Idempotency key reused with different request") if
      record.request_fingerprint != @fingerprint

    if record.previously_new_record?
      return success(record, replayed?: false, record: record)
    end

    return failure("Idempotency request is already being processed", status: 409) if
      record.response_status.nil? || record.response_body.nil?

    success(
      record,
      replayed?: true,
      response_status: record.response_status,
      response_body: record.response_body,
      record: record
    )
  end
end
