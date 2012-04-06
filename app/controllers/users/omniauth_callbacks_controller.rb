class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def ldap

    # the OmniAuth Auth Hash, see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
    auth_hash = request.env["omniauth.auth"]

    #dn = auth_hash['uid']
    #uid = auth_hash['info']['nickname']
    email = auth_hash['info']['email']
    #name = auth_hash['info']['name']
    #first_name = auth_hash['info']['first_name']
    #last_name = auth_hash['info']['last_name']

    if @user = User.find_by_email(email)
      sign_in_and_redirect @user
    else
      @user = User.create(:email => email,
                          :password => 'foo')
      sign_in_and_redirect @user
    end
  end
end