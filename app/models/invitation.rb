class Invitation < ApplicationRecord
  belongs_to :invited_by, class_name: "User"

  before_validation :normalize_email

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :role, inclusion: { in: [ 0, 1 ] }

  def expired?
    expires_at <= Time.current
  end

  def usable?
    accepted_at.nil? && !expired?
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
