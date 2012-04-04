class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def ldap
    ldap_result = request.env["omniauth.auth"]["extra"]["raw_info"]
    username = ldap_result.sAMAccountName[0].to_s
    email = ldap_result.proxyaddresses[0][5..-1].to_s

    if @user = User.find_by_username(username)
      puts "*** blah ***"
      sign_in_and_redirect @user
    else
      puts "*** asdf ***"
      @user = User.create(:username => username,
                          :password => User.generate_random_password)
      sign_in_and_redirect @user
    end
  end
end