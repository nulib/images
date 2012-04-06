require 'spec_helper'

describe Users::OmniauthCallbacksController do
  include Devise::TestHelpers

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:ldap]
  end

  it 'should authenticate and identify user if user is known' do
    get :ldap
    response.should be_redirect
  end
end