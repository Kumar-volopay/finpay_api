class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :family_id, presence: true

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

  def self.revoke_family!(family_id)
    where(family_id: family_id, revoked_at: nil)
      .update_all(revoked_at: Time.current)
  end
end
