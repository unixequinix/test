# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'pundit/rspec'
require "action_mailer"
require "email_spec"
require "email_spec/rspec"

ENV['RAILS_ENV'] ||= 'test'

unless ARGV.any? { |e| e =~ /guard-rspec/ }
  SimpleCov.start do
    add_group "Models", "app/models"
    add_group "Controllers", "app/controllers"
    add_group "Serializers", "app/serializers"
    add_group "Helpers", "app/helpers"
    add_group "Jobs", "app/jobs"
    add_group "Domain Logic", "app/glownet"

    add_filter "/spec/"
    add_filter "/config/"
    add_filter "/vendor/"
    add_filter "/i18n/"
  end

  if ENV['CI'] == 'true'
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end
end

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require "rack/test"

require 'capybara/rspec'
require 'capybara/rails'

# Add additional requires below this line. Rails is not loaded until this point!
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
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :firefox )
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  config.color = true

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
  # Service specs: type: :services
  config.infer_spec_type_from_file_location!

  # Add stuff to make devise work
  config.include AnalyticsHelper, type: :model
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :helper
  config.include FactoryBot::Syntax::Methods
  config.include ControllerMacros
  config.include Warden::Test::Helpers
  config.include Requests::JsonHelpers, type: :api
  config.include Api::V2Helper, type: :api
  config.include Api::V1Helper, type: :api
  config.include ApplicationHelper, type: :feature
  config.include ActionView::Helpers::NumberHelper, type: :feature

  Warden.test_mode!
  Sidekiq::Testing.inline!
  
  config.before(:suite) do
    Sidekiq::Worker.clear_all
  end
  
  config.before(:suite) { FactoryBot.lint } if ENV["LINT"]

  config.after(:each) do
    $reports.redis.flushdb if $reports.present?
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
