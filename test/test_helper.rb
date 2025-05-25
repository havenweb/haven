ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add Devise test helpers
  include Devise::Test::IntegrationHelpers

  # Add more helper methods to be used by all tests here...
end
