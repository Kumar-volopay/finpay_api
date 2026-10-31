class User < ApplicationRecord
  has_many :refresh_tokens, dependent: :destroy

  devise :database_authenticatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  enum :role, {
    admin: 0,
    member: 1
  }

  before_validation :generate_jti, on: :create

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }

  validates :jti, presence: true, uniqueness: true

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
end
