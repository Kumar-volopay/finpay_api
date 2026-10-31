# frozen_string_literal: true

require "rails_helper"

RSpec.describe Receipt do
  subject(:receipt) { build(:receipt) }

  it "belongs to an expense" do
    association = described_class.reflect_on_association(:expense)
    expect(association.macro).to eq(:belongs_to)
  end

  it "requires a file name" do
    receipt.file_name = nil
    expect(receipt).not_to be_valid
  end

  it "requires a content type" do
    receipt.content_type = nil
    expect(receipt).not_to be_valid
  end

  it "requires a storage key" do
    receipt.storage_key = nil
    expect(receipt).not_to be_valid
  end

  it "requires a byte size" do
    receipt.byte_size = nil
    expect(receipt).not_to be_valid
  end

  it "rejects negative byte sizes" do
    receipt.byte_size = -1
    expect(receipt).not_to be_valid
  end

  it "defaults OCR status to pending" do
    expect(receipt.ocr_status).to eq("pending")
  end

  it "encrypts OCR text" do
    receipt.ocr_text = "Extracted receipt text"

    expect(receipt.ocr_text).to eq("Extracted receipt text")
    expect(described_class.encrypted_attributes).to include(:ocr_text)
  end
end
