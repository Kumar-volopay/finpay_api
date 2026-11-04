module Api
  module V1
    class AuthController < ApplicationController
      DUMMY_PASSWORD_HASH = Devise::Encryptor.digest(
        User,
        SecureRandom.hex(32)
      )
      skip_before_action :require_authenticated_user
      skip_after_action :verify_authorized
      rate_limit to: 10, within: 1.minute, only: %i[login register refresh]

      def register
        company = Company.find_by(subdomain: params[:subdomain])

        unless company
          return render json: { error: "Invalid invitation" },
                        status: :unauthorized
        end

        raw_token = params[:invitation_token].to_s

        if raw_token.blank?
          return render json: { error: "Invalid invitation" },
                        status: :unauthorized
        end

        Apartment::Tenant.switch(company.subdomain) do
          digest = Digest::SHA256.hexdigest(raw_token)
          invitation = Invitation.lock.find_by(token_digest: digest)

          unless invitation&.usable? &&
                 invitation.email == params[:email].to_s.strip.downcase
            return render json: { error: "Invalid invitation" },
                          status: :unauthorized
          end

          user = User.new(user_params)
          user.role = User.roles.key(invitation.role)

          if user.save
            invitation.update!(accepted_at: Time.current)

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

        unless company
          return render json: { error: "Invalid credentials" },
                        status: :unauthorized
        end

        Apartment::Tenant.switch(company.subdomain) do
          user = User.find_by(email: params[:email].to_s.downcase.strip)

          password = params[:password].to_s

          if user
            authenticated = user.valid_password?(password)
          else
            Devise::Encryptor.compare(User, DUMMY_PASSWORD_HASH, password)
            authenticated = false
          end

         unless authenticated
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

        company = Company.find_by(id: payload.fetch("company_id"))
        raw_refresh_token = params[:refresh_token].to_s

        unless company && raw_refresh_token.present?
          return render json: { error: "Invalid token" },
                        status: :unauthorized
        end

        digest = Digest::SHA256.hexdigest(raw_refresh_token)

        Apartment::Tenant.switch(company.subdomain) do
          RefreshToken.transaction do
            refresh_token = RefreshToken.lock.find_by(
              token_digest: digest,
              user_id: payload.fetch("sub")
            )

            unless refresh_token && !refresh_token.revoked? &&
                   !refresh_token.expired?
              raise ActiveRecord::RecordNotFound
            end

            JwtDenylist.create!(
              jti: payload.fetch("jti"),
              exp: Time.at(payload.fetch("exp"))
            )

            refresh_token.revoke!
          end
        end

        head :no_content
      rescue JWT::DecodeError, KeyError,
             ActiveRecord::RecordNotFound,
             ActiveRecord::RecordNotUnique
        render json: { error: "Invalid token" }, status: :unauthorized
      end

      def refresh
        raw_refresh_token = params[:refresh_token].to_s

        if raw_refresh_token.blank?
          return render json: { error: "Invalid refresh token" },
                        status: :unauthorized
        end

        company = Company.find_by(subdomain: params[:subdomain])

        unless company
          return render json: { error: "Invalid refresh token" },
                        status: :unauthorized
        end

        result = Authentication::RefreshTokenService.rotate(
          raw_token: raw_refresh_token,
          company: company
        )

        unless result
          return render json: { error: "Invalid refresh token" },
                        status: :unauthorized
        end

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
