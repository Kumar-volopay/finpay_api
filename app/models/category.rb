# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :expenses, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }
end
