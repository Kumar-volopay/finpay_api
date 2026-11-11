# frozen_string_literal: true

class Receipt < ApplicationRecord
  belongs_to :expense

  has_one_attached :file

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
              greater_than: 0,
              less_than_or_equal_to: 10.megabytes
            }

  validate :file_must_be_attached
  validate :file_must_have_allowed_content_type
  validate :file_must_be_within_size_limit

  after_create_commit :enqueue_ocr_processing

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_must_have_allowed_content_type
    return unless file.attached?

    unless %w[application/pdf image/jpeg image/png].include?(file.blob.content_type)
      errors.add(:file, "must be a PDF, JPEG, or PNG")
    end
  end

  def file_must_be_within_size_limit
    return unless file.attached?

    if file.blob.byte_size > 10.megabytes
      errors.add(:file, "must be 10 MB or smaller")
    end
  end

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
