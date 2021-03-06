ENV['RAILS_ENV'] = 'test'

require 'spec_helper'

require File.expand_path('../../config/environment', __FILE__)

require 'rspec/rails'
require 'shoulda/matchers'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  # This will use the defaults of :js and :server_rendering meta tags
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)

  config.include FactoryGirl::Syntax::Methods
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
end

ActiveRecord::Migration.maintain_test_schema!
Capybara.javascript_driver = :webkit
