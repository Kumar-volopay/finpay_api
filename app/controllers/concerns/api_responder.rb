# frozen_string_literal: true

module ApiResponder
  extend ActiveSupport::Concern

  private

  # Standard success response
  def render_success(data:, status: :ok, meta: {})
    render json: {
      data: data,
      meta: meta
    }, status: status
  end

  # Standard error response
  def render_error(code:, message:, details: {}, status: :unprocessable_entity)
    render json: {
      error: {
        code: code,
        message: message,
        details: details
      }
    }, status: status
  end
end
