# frozen_string_literal: true

class OverdueReminderSchedulerWorker
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 5

  def perform
    Company.find_in_batches do |companies|
      Sidekiq::Client.push_bulk(
        "class" => OverdueReminderWorker,
        "args" => companies.map { |company| [ company.id ] }
      )
    end
  end
end
