class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :require_authenticated_user
  after_action :verify_authorized

  def pundit_user
    @current_user
  end

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Forbidden" }, status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not Found" }, status: :not_found
  end

  private

  def require_authenticated_user
    return if @current_user.present?

    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
