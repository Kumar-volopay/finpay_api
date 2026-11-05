# frozen_string_literal: true

module ApiResponder
  extend ActiveSupport::Concern

  private

  def render_success(data:, status: :ok, meta: {})
    render json: {
      data: data,
      meta: meta
    }, status: status
  end

  def render_error(code:, message:, details: [], status: :unprocessable_content)
    normalized_details =
      case details
      when nil
        []
      when Array
        details.map { |detail| normalize_error_detail(detail) }
      when Hash
        details.empty? ? [] : [ details ]
      else
        [ normalize_error_detail(details) ]
      end

    render json: {
      error: {
        code: code,
        message: message,
        details: normalized_details,
        request_id: request.request_id
      }
    }, status: status
  end

  def normalize_error_detail(detail)
    case detail
    when Hash
      detail
    else
      { field: nil, message: detail.to_s }
    end
  end
end
