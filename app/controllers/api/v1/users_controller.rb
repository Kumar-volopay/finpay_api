module Api
  module V1
    class UsersController < ApplicationController
      include TenantLoader

      def show
        user = User.find(params[:id])
        authorize user, :show?

        render json: {
          id: user.id,
          email: user.email,
          role: user.role
        }, status: :ok
      end
    end
  end
end
