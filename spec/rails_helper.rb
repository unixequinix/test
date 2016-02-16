# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
require 'spec_helper'
require 'capybara/rspec'
require 'capybara/poltergeist'

ENV['RAILS_ENV'] ||= 'test'

unless ARGV.any? {|e| e =~ /guard-rspec/ }
  SimpleCov.start do
    add_group "Models", "app/models"
    add_group "Domain Logic", "app/glownet"
    add_group "Forms", "app/forms"
    add_group "Validators", "app/validators"
    add_group "Presenters", "app/presenters"
    add_group "Libraires", "lib"
    add_group "Helpers", "app/helpers"
    add_group "Controllers", "app/controllers"
    add_group "Mailers", "app/mailers"
    add_group "Serializers", "app/serializers"

    add_filter "/spec/"
    add_filter "/config/"
    add_filter "/vendor/"
    add_filter "/i18n/"
  end
end

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'shoulda/matchers'
require 'warden'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!
Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  #
  # Model specs: type: :model
  # Controller specs: type: :controller
  # Request specs: type: :request
  # Feature specs: type: :feature
  # View specs: type: :view
  # Helper specs: type: :helper
  # Mailer specs: type: :mailer
  # Routing specs: type: :routing
  # Service specs: tyoe: :services
  config.infer_spec_type_from_file_location!

  # Add stuff to make devise work
  config.include ControllerMacros, type: :controller
  config.include I18nMacros, type: :feature
  config.include ParametersMacros, type: :feature
  config.include Warden::Test::Helpers


  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Database cleaner
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Warden.test_mode!
  end

  config.before(:suite) do
    Seeder::SeedLoader.create_event_parameters
    Seeder::SeedLoader.create_claim_parameters
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
    Sidekiq::Worker.clear_all
  end

  config.after(:each) do
    Warden.test_reset!
  end

  config.after(:all) do
    DatabaseCleaner.clean_with(:truncation)
    Seeder::SeedLoader.create_event_parameters
    Seeder::SeedLoader.create_claim_parameters
  end

end
