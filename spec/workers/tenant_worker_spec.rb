require "rails_helper"

RSpec.describe TenantWorker do
  let!(:company) do
    subdomain = tenant_subdomain("tenant_worker")
    track_tenant_schema(subdomain)

    Companies::Provision.call(
      name: "Tenant Worker Test",
      subdomain: subdomain
    )
  end

  let(:test_worker_class) do
    Class.new(described_class) do
      def perform_for_tenant(should_raise = false)
        raise "Worker failed" if should_raise

        Apartment::Tenant.current
      end
    end
  end

  describe "#perform" do
    it "switches to the company's tenant while performing the job" do
      result = test_worker_class.new.perform(company.id)

      expect(result).to eq(company.subdomain)
    end

    it "resets the tenant after successful execution" do
      test_worker_class.new.perform(company.id)

      expect(Apartment::Tenant.current).to eq("public")
    end

    it "resets the tenant even when the job raises an error" do
      expect {
        test_worker_class.new.perform(company.id, true)
      }.to raise_error("Worker failed")

      expect(Apartment::Tenant.current).to eq("public")
    end

    it "raises an error when the company does not exist" do
      expect {
        test_worker_class.new.perform(-1)
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(Apartment::Tenant.current).to eq("public")
    end
  end
end
