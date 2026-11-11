# frozen_string_literal: true

module Api
  module V1
    class ReceiptsController < ApplicationController
      include TenantLoader

      def create
        expense = policy_scope(Expense).find(params[:expense_id])
        authorize expense, :show?

        uploaded_file = receipt_params[:file]

        unless uploaded_file.is_a?(ActionDispatch::Http::UploadedFile)
          return render_error(
            code: "invalid_receipt_file",
            message: "A receipt file is required",
            status: :unprocessable_content
          )
        end

        receipt = expense.receipts.build(
          file_name: uploaded_file.original_filename,
          content_type: uploaded_file.content_type,
          byte_size: uploaded_file.size,
          storage_key: SecureRandom.uuid
        )

        receipt.file.attach(uploaded_file)
        receipt.save!

        render_success(
          data: ReceiptSerializer.new(receipt).to_h,
          status: :created
        )
      end

      def show
        expense = policy_scope(Expense).find(params[:expense_id])
        authorize expense, :show?

        receipt = expense.receipts.find(params[:id])

        render_success(data: ReceiptSerializer.new(receipt).to_h)
      end

      private

      def receipt_params
        params.require(:receipt).permit(:file)
      end
    end
  end
end
