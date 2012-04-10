# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Devise::TestHelpers, :type => :controller


  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end

module FactoryGirl
  def self.find_or_create(handle, by=:email)
    tmpl = FactoryGirl.build(handle)
    tmpl.class.send("find_by_#{by}".to_sym, tmpl.send(by)) || FactoryGirl.create(handle)
  end
end

# for request specs
def login(user)
  visit '/'
  click_link "Login"
  fill_in 'user_email', :with => user.email
  fill_in 'user_password', :with => 'archivist1'
  click_on('Sign in')
end

# for OmniAuth specs
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:ldap] = {
    :provider => 'ldap',
    :uid => 'uid=vanessa,ou=people,dc=example,dc=com',
    :info => {
        :name => 'Vanessa Smith',
        :email => 'vanessa@example.com',
        :nickname => 'vanessa'
    }
}
