# frozen_string_literal: true

class Receipt < ApplicationRecord
  belongs_to :expense

  encrypts :ocr_text

  enum :ocr_status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, validate: true

  validates :file_name, presence: true

  validates :content_type,
            presence: true,
            inclusion: { in: %w[application/pdf image/jpeg image/png] }

  validates :storage_key, presence: true, uniqueness: true

  validates :byte_size,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 10.megabytes,
              allow_nil: true
            }

  after_create_commit :enqueue_ocr_processing

  private

  def enqueue_ocr_processing
    tenant = Apartment::Tenant.current
    return if tenant.blank? || tenant == "public"

    company_id = Company.find_by(subdomain: tenant)&.id
    unless company_id
      Rails.logger.warn("Receipt OCR enqueue skipped: Company not found for tenant #{tenant}")
      return
    end

    ReceiptProcessorWorker.perform_async(company_id, id)
  end
end
