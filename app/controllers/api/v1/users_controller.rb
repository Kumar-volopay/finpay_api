module Api
  module V1
    class UsersController < ApplicationController
      include TenantLoader

      def show
        user = policy_scope(User).find(params[:id])

        authorize user, :show?

        render_success(data: {
          id: user.id,
          email: user.email,
          role: user.role
        })
      end
    end
  end
end
