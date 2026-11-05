# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReceiptProcessorWorker do
  let!(:company) do
    subdomain = tenant_subdomain("receipt_worker")
    track_tenant_schema(subdomain)

    Companies::Provision.call(
      name: "Receipt Worker Spec Company",
      subdomain: subdomain
    )
  end

  let(:receipt) do
    Apartment::Tenant.switch(company.subdomain) do
      user = create(:user)
      category = create(:category)
      expense = create(:expense, user: user, category: category)

      create(:receipt, expense: expense)
    end
  end

  describe "#perform" do
    it "processes a pending receipt successfully" do
      described_class.new.perform(company.id, receipt.id)

      Apartment::Tenant.switch(company.subdomain) do
        processed_receipt = Receipt.find(receipt.id)

        expect(processed_receipt).to be_completed
        expect(processed_receipt.ocr_text).to include("Simulated OCR result")
      end
    end

    it "does not process an already completed receipt again" do
      Apartment::Tenant.switch(company.subdomain) do
        receipt.update!(
          ocr_status: :completed,
          ocr_text: "Previously extracted text"
        )
      end

      worker = described_class.new
      expect(worker).not_to receive(:simulate_ocr)

      worker.perform(company.id, receipt.id)

      Apartment::Tenant.switch(company.subdomain) do
        expect(Receipt.find(receipt.id).ocr_text)
          .to eq("Previously extracted text")
      end
    end

    it "marks the receipt as failed when OCR processing raises an error" do
      worker = described_class.new
      allow(worker)
        .to receive(:simulate_ocr)
        .and_raise(StandardError, "OCR processing failed")

      expect {
        worker.perform(company.id, receipt.id)
      }.to raise_error(StandardError, "OCR processing failed")

      Apartment::Tenant.switch(company.subdomain) do
        expect(Receipt.find(receipt.id)).to be_failed
      end
    end

    it "logs and skips when the receipt does not exist" do
      expect(Rails.logger).to receive(:warn).with(
        "ReceiptProcessorWorker skipped: Receipt not found (id: -1)"
      )

      expect {
        described_class.new.perform(company.id, -1)
      }.not_to raise_error
    end
  end
end
