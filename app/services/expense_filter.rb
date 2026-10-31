# frozen_string_literal: true

class ExpenseFilter
  ALLOWED_FILTERS = %w[
    category_id
    status
    from
    to
  ].freeze

  ALLOWED_STATUSES = %w[
    pending
    approved
    rejected
  ].freeze

  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  def initialize(scope, params)
    @scope = scope
    @params = params.to_h.stringify_keys
  end

  def call
    validate_filters!

    expenses = @scope

    expenses = expenses.where(category_id: category_id) if category_id.present?
    expenses = expenses.where(status: status) if status.present?
    expenses = expenses.where("incurred_on >= ?", from_date) if from_date
    expenses = expenses.where("incurred_on <= ?", to_date) if to_date

    expenses
  end

  private

  def validate_filters!
    unknown_filters = @params.keys - ALLOWED_FILTERS

    if unknown_filters.any?
      raise ArgumentError, "Unknown filters: #{unknown_filters.join(', ')}"
    end

    if status.present? && !ALLOWED_STATUSES.include?(status)
      raise ArgumentError, "Invalid expense status"
    end

    validate_date!(:from)
    validate_date!(:to)

    if from_date && to_date && from_date > to_date
      raise ArgumentError, "From date cannot be after to date"
    end
  end

  def category_id
    return if @params["category_id"].blank?

    value = @params["category_id"]
    raise ArgumentError, "Invalid category_id" unless value.to_s.match?(/\A[1-9]\d*\z/)

    value.to_i
  end

  def status
    @params["status"]
  end

  def from_date
    @from_date
  end

  def to_date
    @to_date
  end

  def validate_date!(key)
    value = @params[key.to_s]
    return if value.blank?

    unless value.match?(DATE_FORMAT)
      raise ArgumentError, "Invalid #{key} date"
    end

    parsed_date = Date.iso8601(value)
    instance_variable_set("@#{key}_date", parsed_date)
  rescue Date::Error
    raise ArgumentError, "Invalid #{key} date"
  end
end
