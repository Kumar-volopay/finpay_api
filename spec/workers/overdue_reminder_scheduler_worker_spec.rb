# frozen_string_literal: true

require "rails_helper"

RSpec.describe OverdueReminderSchedulerWorker do
  describe "#perform" do
    it "bulk enqueues one reminder worker for each company" do
      companies = [
        instance_double(Company, id: 101),
        instance_double(Company, id: 102)
      ]

      allow(Company).to receive(:find_in_batches).and_yield(companies)

      expect(Sidekiq::Client).to receive(:push_bulk).with(
        "class" => OverdueReminderWorker,
        "args" => [ [ 101 ], [ 102 ] ]
      ).once

      described_class.new.perform
    end
  end
end
