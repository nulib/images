class PoliciesController < ApplicationController
  load_and_authorize_resource :class=>AdminPolicy

  def index
    @page_title = 'Admin Policies'
    @edit_policies = AdminPolicy.editable_by_user(current_user)
    @read_policies = AdminPolicy.where_user_has_permissions(current_user, [:read])
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
    errors = []
    # if read_user is already edit_user, don't downgrade access
    new_read_user = params[:admin_policy][:permissions][:new_read_user_name] if params[:admin_policy][:permissions]
    if @policy.edit_users.include?(new_read_user)
      params[:admin_policy][:permissions][:new_read_user_name] = ''
      errors <<  "#{new_read_user} is a maintainer.  Maintainers can already use the policy."
    end
    # if read_group is already edit_group, don't downgrade access
    new_read_group = params[:admin_policy][:permissions][:new_read_group_name] if params[:admin_policy][:permissions]
    if @policy.edit_groups.include?(new_read_group)
      params[:admin_policy][:permissions][:new_read_group_name] = ''
      errors <<  "#{new_read_group} is a maintainer.  Maintainers can already use the policy."
    end

    parse_permissions!(params[:admin_policy], [:permissions, :default_permissions])
    @policy.update_attributes(params[:admin_policy])
    respond_to do |format|
      format.json do
        val = [] << params[:admin_policy][:permissions] << params[:admin_policy][:default_permissions]
        data = {}
        if errors.present?
          data[:errors] = errors
        else
          data[:values] = val.flatten.compact
        end
        render :json=>data
      end
      format.html { redirect_to policies_path, :notice =>"Saved changes to #{@policy.title}" }
    end
  end
end
