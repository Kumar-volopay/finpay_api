
require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
end

RSpec.configure do |config|
  # RSpec expectations
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # RSpec mocks
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Allow filtering examples using :focus metadata
  config.filter_run_when_matching :focus

  # Save example status for --only-failures and --next-failure
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Use explicit RSpec syntax instead of monkey-patched methods
  config.disable_monkey_patching!

  # Enable warnings
  config.warnings = true

  # Use documentation format when running a single spec file
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Report the 10 slowest examples and groups
  config.profile_examples = 10

  # Run tests in random order to reveal dependencies between examples
  config.order = :random

  # Make random ordering reproducible using the reported seed
  Kernel.srand config.seed
end
