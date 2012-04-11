class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller  
# Adds Hydra behaviors into the application controller 
  include Hydra::Controller
  def layout_name
   'hydra-head'
  end

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery

  protected
  def selected_files
    session[:files] ||= []
  end
  def selected_files= val
    session[:files] = val
  end

  def enforce_show_permissions
puts "IN show perms"
    #nop
  end
  def enforce_edit_permissions
puts "IN edit perms"
    #nop
  end
  

end
