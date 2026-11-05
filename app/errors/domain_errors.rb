# frozen_string_literal: true

module DomainErrors
  class InvalidInput < StandardError; end
  class IdempotencyKeyUsed < StandardError; end
  class IdempotencyFingerprintMismatch < StandardError; end
end
