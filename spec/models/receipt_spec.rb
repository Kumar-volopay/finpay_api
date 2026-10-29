# frozen_string_literal: true

require "rails_helper"

RSpec.describe Receipt do
  subject(:receipt) { build(:receipt) }

  it "requires a storage key" do
    receipt.storage_key = nil
    expect(receipt).not_to be_valid
  end

  it "defaults OCR status to pending" do
    expect(receipt.ocr_status).to eq("pending")
  end

  it "encrypts OCR text" do
    receipt.ocr_text = "Extracted receipt text"

    expect(receipt.ocr_text).to eq("Extracted receipt text")
    expect(receipt.class.encrypted_attributes).to include(:ocr_text)
   end
end
