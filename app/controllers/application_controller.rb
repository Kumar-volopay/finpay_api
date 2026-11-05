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
    raise ApiErrors::AuthenticationRequired unless @current_user.present?
  end
end
