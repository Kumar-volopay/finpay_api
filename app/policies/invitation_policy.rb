class InvitationPolicy < ApplicationPolicy
  def create?
    user&.admin?
  end
end
