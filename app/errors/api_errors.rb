# frozen_string_literal: true

module ApiErrors
  class TenantNotFound < StandardError
  end



  class IdempotencyKeyUsed < StandardError; end
  class InvalidIdempotencyKey < StandardError; end
  class IdempotencyFingerprintMismatch < StandardError; end
class InvalidInvitation < StandardError; end
class InvalidCredentials < StandardError; end
class InvalidToken < StandardError; end
class TokenExpired < StandardError; end
class InvalidRefreshToken < StandardError; end
  class AuthenticationRequired < StandardError; end
  class InvalidRequest < ArgumentError; end
end
