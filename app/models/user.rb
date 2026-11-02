class User < ApplicationRecord
  has_many :refresh_tokens, dependent: :destroy
  has_many :activity_logs, foreign_key: :actor_id,
                           dependent: :restrict_with_error

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
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
            presence: true,
            length: { minimum: 12 },
            if: -> { new_record? || password.present? }

  validates :jti, presence: true, uniqueness: true

  def disabled?
    disabled_at.present?
  end

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
end
