class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def ldap
    ldap_result = request.env["omniauth.auth"]["extra"]["raw_info"]
    puts ldap_result
    username = ldap_result.uid[0].to_s
    email = ldap_result.mail[0].to_s

    puts "uid: " + username
    puts "email: " + email

    if @user = User.find_by_email(email)
      sign_in_and_redirect @user
    else
      @user = User.create(:email => email,
                          :password => 'foo')
      sign_in_and_redirect @user
    end
  end
end