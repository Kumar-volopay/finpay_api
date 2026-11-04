module Api
  module V1
    class ProtectedController < ApplicationController
      include TenantLoader

      def index
        render json: {
          message: "Authenticated successfully",
          user_id: @current_user.id,
          role: @current_user.role
        }, status: :ok
      end
    end
  end
end
