# frozen_string_literal: true

class ApplicationService
  Result = Struct.new(
    :success, :data, :error, :replayed,
    :response_status, :response_body, :record, :error_code,
    keyword_init: true
  ) do
    def success?
      success
    end

    def replayed?
      replayed
    end
  end

  def self.call(...)
    new(...).call
  end

  private

  def success(data = nil, **attributes)
    Result.new(**{
      success: true,
      data: data,
      error: nil,
      replayed: false
    }.merge(attributes))
  end

  def failure(error, status: 422, code: nil)
    Result.new(
      success: false,
      data: nil,
      error: error,
      replayed: false,
      response_status: status,
      error_code: code
    )
  end
end
