# frozen_string_literal: true

class TenantWorker
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 5

  def perform(company_id, *args)
    company = Company.find_by(id: company_id)

    unless company
      Rails.logger.warn("TenantWorker skipped: Company not found (id: #{company_id})")
      return
    end

    Apartment::Tenant.switch(company.subdomain) do
      perform_for_tenant(*args)
    end
  ensure
    Apartment::Tenant.reset
  end

  def perform_for_tenant(*args)
    raise NotImplementedError,
          "#{self.class} must implement perform_for_tenant"
  end
end
