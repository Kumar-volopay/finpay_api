# frozen_string_literal: true

class ReceiptProcessorWorker < TenantWorker
  sidekiq_options queue: :default, retry: 5

  def perform_for_tenant(receipt_id)
    receipt = Receipt.find(receipt_id)
    processing_error = nil

    receipt.with_lock do
      unless receipt.completed?
        receipt.update!(ocr_status: :processing)

        begin
          ocr_text = simulate_ocr(receipt)

          receipt.update!(
            ocr_text: ocr_text,
            ocr_status: :completed
          )
        rescue StandardError => error
          processing_error = error

          begin
            receipt.update!(ocr_status: :failed)
          rescue StandardError => status_error
            Rails.logger.error(
              "Failed to update receipt #{receipt.id} status: " \
              "#{status_error.class}: #{status_error.message}"
            )
          end
        end
      end
    end

    raise processing_error if processing_error
  end

  private

  def simulate_ocr(receipt)
    "Simulated OCR result for #{receipt.file_name}"
  end
end
