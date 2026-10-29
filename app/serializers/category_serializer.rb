# frozen_string_literal: true

class CategorySerializer
  include Alba::Resource

  attributes :id, :name, :created_at, :updated_at
end
