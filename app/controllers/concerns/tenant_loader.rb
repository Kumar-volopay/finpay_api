# frozen_string_literal: true

module TenantLoader
  extend ActiveSupport::Concern

  included do
    around_action :load_tenant_from_jwt
  end

  private

  def load_tenant_from_jwt
    context = authenticate_tenant
    return unless context

    company, user_id = context

    Apartment::Tenant.switch(company.subdomain) do
      @current_user = User.find_by(id: user_id)

      unless @current_user
        render json: { error: "Unauthorized" }, status: :unauthorized
        next
      end

      yield
    end
  ensure
    Apartment::Tenant.reset
  end

  def authenticate_tenant
    token = bearer_token
    payload = Authentication::TokenService.decode(token)

    company_id = payload["company_id"]
    user_id = payload["sub"]
    jti = payload["jti"]

    raise JWT::DecodeError unless company_id && user_id && jti
    raise JWT::DecodeError if JwtDenylist.exists?(jti: jti)

    company = Company.find_by(id: company_id)
    raise ActiveRecord::RecordNotFound unless company

    [ company, user_id ]
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound,
         Apartment::TenantNotFound, ActiveRecord::StatementInvalid
    render json: { error: "Unauthorized" }, status: :unauthorized
    nil
  end

  def bearer_token
    scheme, token = request.headers["Authorization"].to_s.split(" ", 2)

    raise JWT::DecodeError unless scheme == "Bearer" && token.present?

    token
  end
end
