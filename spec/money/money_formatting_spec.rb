# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyFormatting do
  describe ".fraction_digits" do
    it "returns two decimal places for USD" do
      expect(described_class.fraction_digits("USD")).to eq(2)
    end

    it "returns zero decimal places for JPY" do
      expect(described_class.fraction_digits("JPY")).to eq(0)
    end

    it "returns three decimal places for KWD" do
      expect(described_class.fraction_digits("KWD")).to eq(3)
    end

    it "rejects invalid currency codes" do
      expect { described_class.fraction_digits("usd") }
        .to raise_error(ArgumentError)
    end
  end

  describe ".to_minor_units" do
    it "converts USD to cents" do
      expect(described_class.to_minor_units("12.34", currency: "USD"))
        .to eq(1234)
    end

    it "converts JPY to whole units" do
      expect(described_class.to_minor_units("120", currency: "JPY"))
        .to eq(120)
    end

    it "converts KWD to thousandths" do
      expect(described_class.to_minor_units("1.234", currency: "KWD"))
        .to eq(1234)
    end

    it "rejects excess decimal places" do
      expect { described_class.to_minor_units("1.234", currency: "USD") }
        .to raise_error(ArgumentError)
    end

    it "rejects zero and negative amounts" do
      expect { described_class.to_minor_units("0", currency: "USD") }
        .to raise_error(ArgumentError)

      expect { described_class.to_minor_units("-1.00", currency: "USD") }
        .to raise_error(ArgumentError)
    end
  end

  describe ".round_to_minor_units" do
    it "rounds half up for USD" do
      expect(described_class.round_to_minor_units("1.005", currency: "USD")).to eq(101)
    end

    it "rounds half up for JPY" do
      expect(described_class.round_to_minor_units("1.5", currency: "JPY")).to eq(2)
    end

    it "rejects zero and negative amounts" do
      expect { described_class.round_to_minor_units("0", currency: "USD") }
        .to raise_error(ArgumentError)

      expect { described_class.round_to_minor_units("-1", currency: "USD") }
        .to raise_error(ArgumentError)
    end
  end
end
