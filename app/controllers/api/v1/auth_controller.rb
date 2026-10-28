module Api
  module V1
    class AuthController < ApplicationController
      def register
        company = Company.find_by(subdomain: params[:subdomain])
        return render json: { error: "Invalid company" }, status: :not_found unless company

        Apartment::Tenant.switch(company.subdomain) do
          user = User.new(user_params)
          user.role = :member

          if user.save
            token = Authentication::TokenService.encode(
              user: user,
              company_id: company.id
            )
            refresh_token = Authentication::RefreshTokenService.issue(user: user)

            render json: {
              user: { id: user.id, email: user.email, role: user.role },
              access_token: token,
              refresh_token: refresh_token
            }, status: :created
          else
            render json: { errors: user.errors.full_messages },
                   status: :unprocessable_entity
          end
        end
      end

      def login
        company = Company.find_by(subdomain: params[:subdomain])
        return render json: { error: "Invalid credentials" }, status: :unauthorized unless company

        Apartment::Tenant.switch(company.subdomain) do
          user = User.find_by(email: params[:email]&.downcase&.strip)

          unless user&.valid_password?(params[:password])
            return render json: { error: "Invalid credentials" },
                          status: :unauthorized
          end

          token = Authentication::TokenService.encode(
            user: user,
            company_id: company.id
          )
          refresh_token = Authentication::RefreshTokenService.issue(user: user)

          render json: {
            user: { id: user.id, email: user.email, role: user.role },
            access_token: token,
            refresh_token: refresh_token
          }, status: :ok
        end
      end

      def logout
        payload = Authentication::TokenService.decode(bearer_token)
        JwtDenylist.create!(
          jti: payload.fetch("jti"),
          exp: Time.at(payload.fetch("exp"))
        )

        head :no_content
      rescue JWT::DecodeError, KeyError, ActiveRecord::RecordNotUnique
        render json: { error: "Invalid token" }, status: :unauthorized
      end


      def refresh
        raw_refresh_token = params[:refresh_token].to_s
        return render json: { error: "Invalid refresh token" },
              status: :unauthorized if raw_refresh_token.blank?

        company = Company.find_by(subdomain: params[:subdomain])
        return render json: { error: "Invalid refresh token" },
              status: :unauthorized unless company

        result = Authentication::RefreshTokenService.rotate(
          raw_token: raw_refresh_token,
          company: company
      )

      return render json: { error: "Invalid refresh token" },
              status: :unauthorized unless result

      user, new_refresh_token = result

      new_access_token = Authentication::TokenService.encode(
        user: user,
        company_id: company.id
      )

      render json: {
          access_token: new_access_token,
          refresh_token: new_refresh_token
        }, status: :ok
      end


      private

      def user_params
        params.permit(:email, :password, :password_confirmation)
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        scheme, token = header.split(" ", 2)
        raise JWT::DecodeError unless scheme == "Bearer" && token.present?

        token
      end
    end
  end
end
