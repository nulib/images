class PoliciesController < ApplicationController
  load_and_authorize_resource :class=>AdminPolicy

  def index
    @page_title = 'Admin Policies'
    @policies = AdminPolicy.find_with_conditions({})
  end

  def new
    @page_title = 'Create a policy'
  end

  def edit
    @page_title = 'Edit policy'
  end

  def create
    parse_permissions!(params[:admin_policy], [:permissions, :default_permissions])
    @policy.apply_depositor_metadata(current_user.user_key)
    @policy.attributes=params[:admin_policy]
    @policy.save

    redirect_to policies_path
  end

  def update
    parse_permissions!(params[:admin_policy], [:permissions, :default_permissions])
    @policy.update_attributes(params[:admin_policy])
    respond_to do |format|
      format.json { render :json=>params[:admin_policy][:permissions] }
      format.html { redirect_to policies_path, :notice =>"Saved changes to #{@policy.title}" }
    end
  end
end
