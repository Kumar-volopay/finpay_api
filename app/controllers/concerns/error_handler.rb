# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError do
      render_error(
        code: "forbidden",
        message: "You are not authorized to perform this action",
        status: :forbidden
      )
    end

    rescue_from ActiveRecord::RecordNotFound do
      render_error(
        code: "not_found",
        message: "Resource not found",
        status: :not_found
      )
    end

    rescue_from ActiveRecord::RecordInvalid do |error|
      render_error(
        code: "validation_error",
        message: "Record validation failed",
        details: error.record.errors.full_messages,
        status: :unprocessable_entity
      )
    end

    rescue_from AASM::InvalidTransition do
      render_error(
        code: "invalid_transition",
        message: "Invalid expense status transition",
        status: :unprocessable_entity
      )
    end

    rescue_from ApiErrors::AuthenticationRequired do
  render_error(
    code: "unauthorized",
    message: "Authentication required",
    status: :unauthorized
  )
end

rescue_from ApiErrors::InvalidRequest do |error|
  render_error(code: "invalid_request", message: error.message, status: :unprocessable_entity)
end

    rescue_from ApiErrors::TenantNotFound do
      render_error(
        code: "unauthorized",
        message: "Authentication required",
        status: :unauthorized
      )
    end

    rescue_from ApiErrors::InvalidTransition do
      render_error(
        code: "invalid_transition",
        message: "Invalid expense status transition",
        status: :unprocessable_entity
      )
    end

    rescue_from ApiErrors::IdempotencyConflict do
      render_error(
        code: "idempotency_conflict",
        message: "Idempotency key conflicts with an existing request",
        status: :conflict
      )
    end
rescue_from ApiErrors::InvalidInvitation do
  render_error(code: "invalid_invitation",
    message: "Invalid invitation", status: :unauthorized)
end

rescue_from ApiErrors::InvalidCredentials do
  render_error(code: "invalid_credentials",
    message: "Invalid credentials", status: :unauthorized)
end

rescue_from ApiErrors::InvalidToken do
  render_error(code: "invalid_token",
    message: "Invalid token", status: :unauthorized)
end

rescue_from ApiErrors::InvalidRefreshToken do
  render_error(code: "invalid_refresh_token",
    message: "Invalid refresh token", status: :unauthorized)
end
  end
end
