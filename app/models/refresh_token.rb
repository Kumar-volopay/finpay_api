class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> {
    where(revoked_at: nil).where("expires_at > ?", Time.current)
  }

  def revoke!
    update!(revoked_at: Time.current)
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end
end
