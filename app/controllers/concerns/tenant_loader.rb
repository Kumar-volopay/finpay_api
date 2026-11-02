module TenantLoader
  extend ActiveSupport::Concern

  included do
    prepend_around_action :load_tenant_from_jwt
  end

  private

  def load_tenant_from_jwt
    begin
      token = bearer_token
      payload = Authentication::TokenService.decode(token)

      company_id = payload["company_id"]
      user_id = payload["sub"]
      jti = payload["jti"]

      raise JWT::DecodeError unless company_id && user_id && jti

      revoked = JwtDenylist.exists?(jti: jti)
      raise JWT::DecodeError if revoked

      company = Company.find_by(id: company_id)
      raise ActiveRecord::RecordNotFound unless company

    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    begin
      Apartment::Tenant.switch(company.subdomain) do
        @current_user = User.find_by(id: user_id)

        unless @current_user
          render json: { error: "Unauthorized" }, status: :unauthorized
          next
        end

        yield
      end

    rescue Apartment::TenantNotFound
      render json: { error: "Unauthorized" }, status: :unauthorized

    ensure
      Apartment::Tenant.reset
    end
  end

  def bearer_token
    scheme, token = request.headers["Authorization"].to_s.split(" ", 2)

    raise JWT::DecodeError unless scheme == "Bearer" && token.present?

    token
  end
end
