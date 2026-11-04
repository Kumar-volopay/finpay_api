# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization
  include ApiResponder
  include ErrorHandler

  before_action :require_authenticated_user
  after_action :verify_authorized

  def pundit_user
    @current_user
  end

  private

  def require_authenticated_user
    return if @current_user.present?

    render_error(
      code: "unauthorized",
      message: "Authentication required",
      status: :unauthorized
    )
  end
end
