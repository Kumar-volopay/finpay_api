module TenantLoader
  extend ActiveSupport::Concern

  included do
    around_action :load_tenant_from_jwt
  end

  private

  def load_tenant_from_jwt
    token = bearer_token
    payload = Authentication::TokenService.decode(token)

    company_id = payload["company_id"]
    user_id = payload["sub"]
    jti = payload["jti"]

    raise JWT::DecodeError unless company_id && user_id && jti

    # Check revocation in the public schema before switching tenants.
    # Check revocation in the public schema before switching tenants.
    revoked = JwtDenylist.exists?(jti: jti)

    raise JWT::DecodeError if revoked


    company = Company.find_by(id: company_id)
    raise ActiveRecord::RecordNotFound unless company

    Apartment::Tenant.switch(company.subdomain) do
      @current_user = User.find_by(id: user_id)
      raise ActiveRecord::RecordNotFound unless @current_user

      yield
    end
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound,
         Apartment::TenantNotFound, ActiveRecord::StatementInvalid
    render json: { error: "Unauthorized" }, status: :unauthorized
  ensure
    Apartment::Tenant.reset
  end

  def bearer_token
    scheme, token = request.headers["Authorization"].to_s.split(" ", 2)

    raise JWT::DecodeError unless scheme == "Bearer" && token.present?

    token
  end
end
