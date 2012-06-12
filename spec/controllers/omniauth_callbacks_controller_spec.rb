require 'spec_helper'

describe Users::OmniauthCallbacksController do
  include Devise::TestHelpers

  before do
    OmniAuth.config.mock_auth[:ldap] = {
      :provider => 'ldap',
      :uid=> "uid=vanessa,ou=people,dc=example,dc=com",
      :info => {
          :name => 'Vanessa User',
          :email => 'vanessa@example.com',
          :nickname =>  'vanessa'
      },
      :extra => {
        :raw_info => {
            :edupersonaffiliation => ["staff", "student"]
        }
      }
    }
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:ldap]
  end

  it 'should authenticate and identify user if user is known' do
    get :ldap
    response.should be_redirect
  end
end
