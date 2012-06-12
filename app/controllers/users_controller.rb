class UsersController < ApplicationController
  before_filter :authenticate_user!
  #add a user to a group
  def create
    #TODO validate that the params[:id] is a legal value for user
    @group = Group.find(params[:group_id])
    authorize! :edit, @group
    Hydra::LDAP.add_users_to_group(@group.code, [params[:id]])
    redirect_to edit_group_path(@group), :notice=>"Added member #{params[:id]}"
  end

  #remove a user from a group
  def destroy
    @group = Group.find(params[:group_id])
    authorize! :edit, @group
    Hydra::LDAP.remove_users_from_group(@group.code, [params[:id]])
    redirect_to edit_group_path(@group), :notice=>"Removed member #{params[:id]}"
  end
end
