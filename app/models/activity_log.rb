# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  belongs_to :expense
  belongs_to :actor, class_name: "User"

  validates :action, presence: true
  validates :from_state, presence: true
  validates :to_state, presence: true

  before_update :prevent_modification
  before_destroy :prevent_deletion

  private

  def prevent_modification
    raise ActiveRecord::ReadOnlyRecord, "Activity logs cannot be modified"
  end

  def prevent_deletion
    raise ActiveRecord::ReadOnlyRecord, "Activity logs cannot be deleted"
  end
end
