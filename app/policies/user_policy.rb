class UserPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    user&.admin? || record.id == user&.id
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin? || record.id == user&.id
  end

  def destroy?
    user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.admin?

      scope.where(id: user&.id)
    end
  end
end
