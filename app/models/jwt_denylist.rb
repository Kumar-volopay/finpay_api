class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "public.jwt_denylist"

  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true
end
