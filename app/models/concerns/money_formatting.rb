# frozen_string_literal: true

require "bigdecimal"

module MoneyFormatting
  CURRENCIES_WITH_ZERO_DECIMALS = %w[JPY KRW].freeze
  CURRENCIES_WITH_THREE_DECIMALS = %w[BHD KWD OMR].freeze

  def self.fraction_digits(currency)
    raise ArgumentError, "Currency must be a three-letter uppercase code" unless
      currency.is_a?(String) && currency.match?(/\A[A-Z]{3}\z/)

    case currency
    when *CURRENCIES_WITH_ZERO_DECIMALS then 0
    when *CURRENCIES_WITH_THREE_DECIMALS then 3
    else 2
    end
  end

  def self.to_minor_units(amount, currency:)
    digits = fraction_digits(currency)
    decimal = BigDecimal(amount.to_s)

    raise ArgumentError, "Amount must be positive" unless decimal.positive?

    scaled = decimal * (10**digits)

    unless scaled.frac.zero?
      raise ArgumentError, "Amount has too many decimal places for #{currency}"
    end

    scaled.to_i
  rescue TypeError, ArgumentError => e
    raise e if e.message.start_with?("Currency", "Amount")

    raise ArgumentError, "Invalid monetary amount"
  end

  def self.round_to_minor_units(amount, currency:)
    digits = fraction_digits(currency)
    decimal = BigDecimal(amount.to_s)

    raise ArgumentError, "Amount must be positive" unless decimal.positive?

    (decimal * (10**digits)).round(0, :half_up).to_i
  rescue TypeError, ArgumentError => e
    raise e if e.message.start_with?("Currency", "Amount")

    raise ArgumentError, "Invalid monetary amount"
  end

  def self.round_to_minor_units(amount, currency:)
    digits = fraction_digits(currency)
    decimal = BigDecimal(amount.to_s)

    raise ArgumentError, "Amount must be positive" unless decimal.positive?

    (decimal * (10**digits)).round(0, :half_up).to_i
  rescue TypeError, ArgumentError => e
    raise e if e.message.start_with?("Currency", "Amount")

    raise ArgumentError, "Invalid monetary amount"
  end
end
