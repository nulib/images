class PoliciesController < ApplicationController
  load_and_authorize_resource :class=>AdminPolicy

  def new
    @page_title = 'Create a policy'
  end

  def edit
    @page_title = 'Edit policy'
  end

  def create
    parse_permissions!(params[:admin_policy])
    @policy.update_attributes(params[:admin_policy])
    redirect_to policies_path
  end

  def update
    parse_permissions!(params[:admin_policy])
    @policy.update_attributes(params[:admin_policy])
    redirect_to policies_path, :notice =>"Saved changes to #{@policy.title}"
  end
end
