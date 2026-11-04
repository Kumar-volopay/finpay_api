FactoryBot.define do
  factory :receipt do
    association :expense
    file_name { "receipt.pdf" }
    content_type { "application/pdf" }
    byte_size { 1024 }
    sequence(:storage_key) { |n| "receipts/test-#{n}.pdf" }
    ocr_status { "pending" }
    ocr_text { "Test OCR text" }
  end
end
