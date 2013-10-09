class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def ldap
    @user = User.find_for_ldap_oauth(request.env["omniauth.auth"], current_user)

   begin
     # eduPersonAffiliation (e.g. "staff, student, faculty")
     @user.affiliations = request.env["omniauth.auth"][:extra][:raw_info][:edupersonaffiliation]
   rescue Exception=>e
     logger.error("LDAP Error:" << e.message)
   ensure
      if @user.persisted?
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Ldap"
        sign_in_and_redirect @user, :event => :authentication
      else
        session["devise.ldap_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_url
      end
   end
  end
  
  # After login, redirect to previous_url (where the user was trying to go before login but got denied)
  # or root path. This overrides a devise gem method.
  def after_sign_in_path_for(resource)
     if session[:previous_url].present?
      session[:previous_url]
     else
      super
    end
  end
  
end
