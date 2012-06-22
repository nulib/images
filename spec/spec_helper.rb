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

  config.before(:suite) do
    ## Clean out the repository
    begin
      Multiresimage.find(:all, :rows=>1000).each do |m|
        ### Delete everything except the fixture
        m.delete unless /^inu:dil-/.match(m.pid)
      end
      DILCollection.find(:all, :rows=>1000).each(&:delete)
    rescue ActiveFedora::ObjectNotFoundError
      #nop - index is out of synch with repository. Try solrizing
    end
  end
end

module FactoryGirl
  def self.find_or_create(handle, by=:email)
    tmpl = FactoryGirl.build(handle)
    tmpl.class.send("find_by_#{by}".to_sym, tmpl.send(by)) || FactoryGirl.create(handle)
  end
end

# for request specs
def login(user)
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:ldap] = {
    :provider => 'ldap',
    :uid=> "uid=#{user.uid},ou=people,dc=example,dc=com",
    :info => {
        :name => user.uid + ' User',
        :email => user.uid + '@example.com',
        :nickname => user.uid 
    },
    :extra => {
      :raw_info => {
          :edupersonaffiliation => user.affiliations
      }
    }
  }
  Hydra::LDAP.stub(:groups_for_user).with(user.uid).and_return(user.affiliations)
  Hydra::LDAP.stub(:groups_owned_by_user).with(user.uid).and_return([])

  visit '/'
  click_link "Login"
  click_link "sign in with LDAP"
  page.should have_selector("a[href='/users/edit']", :text=> user.email)
  
end

