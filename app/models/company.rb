class Company < ApplicationRecord
  RESERVED_SUBDOMAINS = %w[
    public
    pg_catalog
    information_schema
    pg_toast
  ].freeze

  attr_readonly :subdomain

  validates :name, presence: true

  validates :subdomain,
            presence: true,
            uniqueness: true,
            format: {
              with: /\A[a-z][a-z0-9_]{2,30}\z/
            },
            exclusion: {
              in: RESERVED_SUBDOMAINS,
              message: "is reserved"
            }
end
