# frozen_string_literal: true

class ReceiptProcessorWorker < TenantWorker
  sidekiq_options queue: :default, retry: 5

  def perform_for_tenant(receipt_id)
    receipt = Receipt.find_by(id: receipt_id)

    unless receipt
      Rails.logger.warn("ReceiptProcessorWorker skipped: Receipt not found (id: #{receipt_id})")
      return
    end

    claimed = receipt.with_lock do
      if receipt.completed? || receipt.processing?
        false
      else
        receipt.update!(ocr_status: :processing)
        true
      end
    end

    return unless claimed

    begin
      ocr_text = simulate_ocr(receipt)

      receipt.update!(
        ocr_text: ocr_text,
        ocr_status: :completed
      )
    rescue StandardError => error
      begin
        receipt.update!(ocr_status: :failed)
      rescue StandardError => status_error
        Rails.logger.error("Failed to update receipt #{receipt.id} status: #{status_error.class}: #{status_error.message}")
      end

      raise error
    end
  end

  private

  def simulate_ocr(receipt)
    "Simulated OCR result for #{receipt.file_name}"
  end
end
