module Api
  module V1
    class ProtectedController < ApplicationController
      include TenantLoader

      def index
        render_success(data: {
          message: "Authenticated successfully",
          user_id: @current_user.id,
          role: @current_user.role
        })
      end
    end
  end
end
