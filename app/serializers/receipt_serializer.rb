# frozen_string_literal: true

class ReceiptSerializer
  include Alba::Resource

  attributes :id, :expense_id, :file_name, :content_type,
             :byte_size, :ocr_status, :ocr_text, :created_at, :updated_at
end
