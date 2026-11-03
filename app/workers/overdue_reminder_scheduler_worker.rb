# frozen_string_literal: true

class OverdueReminderSchedulerWorker
  include Sidekiq::Job

  sidekiq_options queue: :critical, retry: 5

  def perform
    Apartment::Tenant.switch("public") do
      Company.find_each do |company|
        OverdueReminderWorker.perform_async(company.id)
      end
    end
  end
end
