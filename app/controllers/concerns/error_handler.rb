# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Keep this first: Rails checks rescue handlers in reverse declaration order.
    rescue_from StandardError do |error|
      Rails.logger.error(
        "[API ERROR] request_id=#{request.request_id} " \
        "exception=#{error.class} message=#{error.message}\n" \
        "#{error.backtrace&.join("\n")}"
      )

      render_error(
        code: "internal_server_error",
        message: "An unexpected error occurred",
        status: :internal_server_error
      )
    end

    rescue_from ActionController::TooManyRequests do
      render_error(
        code: "rate_limit_exceeded",
        message: "Too many requests. Please try again later.",
        status: :too_many_requests
      )
    end

    rescue_from ActionController::ParameterMissing do
      render_error(
        code: "parameter_missing",
        message: "A required request parameter is missing",
        status: :bad_request
      )
    end

    rescue_from ActionDispatch::Http::Parameters::ParseError do
      render_error(
        code: "invalid_json",
        message: "Request body contains invalid JSON",
        status: :bad_request
      )
    end

    rescue_from ActiveRecord::RecordNotDestroyed do |error|
      render_error(
        code: "record_not_destroyed",
        message: "Resource could not be deleted",
        details: error.record.errors.map do |item|
          { field: item.attribute.to_s, message: item.message }
        end,
        status: :unprocessable_content
      )
    end

    rescue_from ActiveRecord::RecordNotUnique do
      render_error(
        code: "record_not_unique",
        message: "A record with the same unique value already exists",
        status: :conflict
      )
    end

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
        details: error.record.errors.map do |item|
          { field: item.attribute.to_s, message: item.message }
        end,
        status: :unprocessable_content
      )
    end

    rescue_from AASM::InvalidTransition do
      render_error(
        code: "invalid_transition",
        message: "Invalid expense status transition",
        status: :unprocessable_content
      )
    end

    rescue_from ApiErrors::AuthenticationRequired do
      render_error(
        code: "unauthorized",
        message: "Authentication required",
        status: :unauthorized
      )
    end

    rescue_from DomainErrors::InvalidInput do |error|
      render_error(
        code: "invalid_request",
        message: error.message,
        status: :unprocessable_content
      )
    end

    rescue_from ApiErrors::InvalidRequest do |error|
      render_error(
        code: "invalid_request",
        message: error.message,
        status: :unprocessable_content
      )
    end

    rescue_from ApiErrors::TenantNotFound do
      render_error(
        code: "unauthorized",
        message: "Authentication required",
        status: :unauthorized
      )
    end


    rescue_from DomainErrors::IdempotencyKeyUsed do
      render_error(
        code: "idempotency_key_used",
        message: "Idempotency key is already associated with another expense",
        status: :conflict
      )
    end

    rescue_from DomainErrors::IdempotencyFingerprintMismatch do
      render_error(
        code: "idempotency_fingerprint_mismatch",
        message: "Idempotency key was reused with a different request",
        status: :conflict
      )
    end

    rescue_from ApiErrors::InvalidIdempotencyKey do
      render_error(
        code: "invalid_idempotency_key",
        message: "Invalid Idempotency-Key",
        status: :bad_request
      )
    end

    rescue_from ApiErrors::InvalidInvitation do
      render_error(
        code: "invalid_invitation",
        message: "Invalid invitation",
        status: :unauthorized
      )
    end

    rescue_from ApiErrors::InvalidCredentials do
      render_error(
        code: "invalid_credentials",
        message: "Invalid credentials",
        status: :unauthorized
      )
    end

    rescue_from ApiErrors::InvalidToken do
      render_error(
        code: "invalid_token",
        message: "Invalid token",
        status: :unauthorized
      )
    end

    rescue_from ApiErrors::TokenExpired do
      render_error(
        code: "token_expired",
        message: "Token has expired",
        status: :unauthorized
      )
    end

    rescue_from ApiErrors::InvalidRefreshToken do
      render_error(
        code: "invalid_refresh_token",
        message: "Invalid refresh token",
        status: :unauthorized
      )
    end
  end
end
