ENV["RAILS_ENV"] ||= "test"

require_relative "../../../config/environment.rb"

require "rspec/rails"
require "factory_girl_rails"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
dir = File.dirname(__FILE__)
Dir["#{dir}/support/*.rb"].each { |f| require f }
Dir["#{dir}/factories/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  # config.order = "random"

  config.include FactoryGirl::Syntax::Methods

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use a custom formatter
  # config.formatter = :progress # :documentation

  # Sidekiq runs jobs immediatelly
  Sidekiq::Testing.inline!

  config.before(:suite) do
    Seeder::SeedLoader.create_event_parameters
    Seeder::SeedLoader.create_claim_parameters
    Sidekiq::Worker.clear_all
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
