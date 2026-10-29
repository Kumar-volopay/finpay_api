class ApplicationController < ActionController::API
  include Pundit::Authorization

  def pundit_user
    @current_user
  end

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
