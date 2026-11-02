# frozen_string_literal: true

class ApplicationService
  Result = Struct.new(
    :success?,
    :data,
    :error,
    :replayed?,
    :response_status,
    :response_body,
    :record,
    keyword_init: true
  )

  def self.call(...)
    new(...).call
  end

  private

  def success(data = nil, **attributes)
    Result.new(
      success?: true,
      data: data,
      error: nil,
      replayed?: false,
      **attributes
    )
  end

  def failure(error, status: 422)
    Result.new(
      success?: false,
      data: nil,
      error: error,
      replayed?: false,
      response_status: status
    )
  end
end
