# frozen_string_literal: true

require "rails_helper"

RSpec.describe OverdueReminderSchedulerWorker do
  describe "#perform" do
    it "enqueues one reminder worker for each company" do
      companies = [
        instance_double(Company, id: 101),
        instance_double(Company, id: 102)
      ]

      allow(Company).to receive(:find_each).and_yield(companies[0]).and_yield(companies[1])

      expect(OverdueReminderWorker)
        .to receive(:perform_async).with(101).once

      expect(OverdueReminderWorker)
        .to receive(:perform_async).with(102).once

      described_class.new.perform
    end
  end
end
