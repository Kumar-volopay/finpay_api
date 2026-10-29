# frozen_string_literal: true

module MoneyFormatting
  CURRENCIES_WITH_ZERO_DECIMALS = %w[JPY KRW].freeze
  CURRENCIES_WITH_THREE_DECIMALS = %w[BHD KWD OMR].freeze

  def self.fraction_digits(currency)
    case currency
    when *CURRENCIES_WITH_ZERO_DECIMALS then 0
    when *CURRENCIES_WITH_THREE_DECIMALS then 3
    else 2
    end
  end

  def self.to_minor_units(amount, currency:)
    digits = fraction_digits(currency)
    decimal = BigDecimal(amount.to_s)
    scaled = decimal * (10**digits)

    unless scaled.frac.zero?
      raise ArgumentError, "Amount has too many decimal places for #{currency}"
    end

    scaled.to_i
  end
end
