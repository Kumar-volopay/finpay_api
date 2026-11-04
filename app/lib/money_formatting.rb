# frozen_string_literal: true

require "bigdecimal"

module MoneyFormatting
  class InvalidAmount < ArgumentError; end

  CURRENCIES_WITH_ZERO_DECIMALS = %w[
    JPY KRW VND CLP ISK UGX XOF XAF PYG
  ].freeze
  CURRENCIES_WITH_THREE_DECIMALS = %w[
    BHD KWD OMR JOD TND LYD IQD
  ].freeze

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
    decimal =
      begin
        BigDecimal(amount.to_s)
      rescue ArgumentError, TypeError
        raise InvalidAmount, "Invalid monetary amount"
      end
    raise ArgumentError, "Amount must be finite" unless decimal.finite?

    raise ArgumentError, "Amount must be positive" unless decimal.positive?

    scaled = decimal * (10**digits)

    unless scaled.frac.zero?
      raise ArgumentError, "Amount has too many decimal places for #{currency}"
    end

    scaled.to_i
  end

  def self.round_to_minor_units(amount, currency:)
    digits = fraction_digits(currency)
    decimal =
      begin
        BigDecimal(amount.to_s)
      rescue ArgumentError, TypeError
        raise InvalidAmount, "Invalid monetary amount"
      end
    raise ArgumentError, "Amount must be finite" unless decimal.finite?

    raise ArgumentError, "Amount must be positive" unless decimal.positive?

    rounded = (decimal * (10**digits)).round(0, :half_up).to_i
    raise ArgumentError, "Amount must be positive after rounding" unless rounded.positive?

    rounded
  end
end
