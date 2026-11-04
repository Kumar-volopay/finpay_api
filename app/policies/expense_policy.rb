# frozen_string_literal: true

class ExpensePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    admin? || own_expense?
  end

  def create?
    user.present?
  end

  def update?
    pending? && (admin? || own_expense?)
  end

  def destroy?
    pending? && (admin? || own_expense?)
  end

  def approve?
    admin? && !own_expense?
  end

  def reject?
    admin?
  end

  def reimburse?
    admin? && !own_expense?
  end

  def archive?
    admin? && record.reimbursed?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      return scope.all if user.admin?

      scope.where(user_id: user.id)
    end
  end

  private

  def admin?
    !!user&.admin?
  end

  def own_expense?
    record.user_id == user&.id
  end

  def pending?
    record.pending?
  end
end
