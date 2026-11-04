# frozen_string_literal: true

module TenantLoader
  extend ActiveSupport::Concern

  included do
    prepend_around_action :load_tenant_from_jwt
  end

  private

  def load_tenant_from_jwt
    token = bearer_token
    payload = Authentication::TokenService.decode(token)

    company_id = payload["company_id"]
    user_id = payload["sub"]
    jti = payload["jti"]

    raise JWT::DecodeError unless company_id && user_id && jti

    revoked = JwtDenylist.exists?(jti: jti)
    raise JWT::DecodeError if revoked

    company = Company.find_by(id: company_id)
    raise ApiErrors::TenantNotFound unless company

    @current_company = company

    Apartment::Tenant.switch(company.subdomain) do
      @current_user = User.find_by(id: user_id)

      raise ApiErrors::InvalidToken unless @current_user

      yield
    end
  rescue JWT::DecodeError
    raise ApiErrors::InvalidToken
  rescue Apartment::TenantNotFound
    raise ApiErrors::TenantNotFound
  ensure
    Apartment::Tenant.reset
  end

  def bearer_token
    scheme, token = request.headers["Authorization"].to_s.split(" ", 2)

    raise ApiErrors::AuthenticationRequired unless scheme == "Bearer" && token.present?

    token
  end
end
