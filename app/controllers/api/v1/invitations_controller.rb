module Api
  module V1
    class InvitationsController < ApplicationController
      include TenantLoader

      def create
        authorize Invitation

        invitation, raw_token = Authentication::InvitationService.create(
          user: @current_user,
          email: params[:email]
        )

        render json: {
          invitation: {
            email: invitation.email,
            expires_at: invitation.expires_at
          },
          invitation_token: raw_token
        }, status: :created
      end
    end
  end
end
