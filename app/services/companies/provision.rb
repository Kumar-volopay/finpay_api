
module Companies
  class Provision
    def self.call(name:, subdomain:)
      new(name:, subdomain:).call
    end

    def initialize(name:, subdomain:)
      @name = name
      @subdomain = subdomain
    end

    def call
      ActiveRecord::Base.transaction(requires_new: true) do
        company = Company.create!(
          name: @name,
          subdomain: @subdomain
        )

        Apartment::Tenant.create(@subdomain)

        company
      end
    end
  end
end
