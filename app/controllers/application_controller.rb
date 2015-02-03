class ApplicationController < ActionController::Base
layout "images"

  rescue_from CanCan::AccessDenied do |exception|
    # Store the url the user was trying to get to in the session. If they log in, they will get redirected to it.
    session[:previous_url] = request.fullpath unless request.xhr?
    redirect_to  "/users/sign_in"
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render :file => "#{Rails.root}/public/404", :status => 404, :layout => false
  end


  # Adds a few additional behaviors into the application controller
   include Blacklight::Controller

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

  private


  def parse_permissions!(params, keys=[:permissions])
    keys.each do |key|
      if params.has_key?(key)
        permissions_params = params[key]
        reformatted_params = []
        if permissions_params["new_edit_user_name"].present?
          reformatted_params << {:name=>permissions_params["new_edit_user_name"], :access=>'edit', :type=>"user"}
        end
        if permissions_params["new_edit_group_name"].present?
          reformatted_params << {:name=>permissions_params["new_edit_group_name"], :access=>'edit', :type=>"group"}
        end
        if permissions_params["new_read_user_name"].present?
puts "setting #{permissions_params["new_read_user_name"]}"
          reformatted_params << {:name=>permissions_params["new_read_user_name"], :access=>'read', :type=>"user"}
        end
        if permissions_params["new_read_group_name"].present?
          reformatted_params << {:name=>permissions_params["new_read_group_name"], :access=>'read', :type=>"group"}
        end
        if permissions_params["new_user_name"].present?
          reformatted_params << {:name=>permissions_params["new_user_name"], :access=>permissions_params["new_user_permission"], :type=>"user"}
        end
        if permissions_params["new_group_name"].present?
          reformatted_params << {:name=>permissions_params["new_group_name"], :access=>permissions_params["new_group_permission"], :type=>"group"}
        end
        if permissions_params.has_key?("user")
          permissions_params["user"].each_pair do |name, access|
            reformatted_params << {:name=>name, :access=>access, :type=>"user"}
          end
        end
        if permissions_params.has_key?("group")
          permissions_params["group"].each_pair do |name, access|
            reformatted_params << {:name=>name, :access=>access, :type=>"group"}
          end
        end
        params[key] = reformatted_params
      end
    end
    params
  end


end
