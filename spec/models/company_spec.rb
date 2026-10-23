
require "rails_helper"

RSpec.describe Company, type: :model do
  describe "validations" do
    subject { build(:company) }

    it "is valid with a name and valid subdomain" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      subject.name = nil

      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires a subdomain" do
      subject.subdomain = nil

      expect(subject).not_to be_valid
      expect(subject.errors[:subdomain]).to include("can't be blank")
    end

    it "rejects an invalid subdomain format" do
      subject.subdomain = "1invalid"

      expect(subject).not_to be_valid
      expect(subject.errors[:subdomain]).to include("is invalid")
    end

    it "rejects duplicate subdomains" do
      create(:company, subdomain: "acme")
      duplicate = build(:company, subdomain: "acme")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:subdomain]).to include("has already been taken")
    end
  end
end
