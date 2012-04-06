class GroupsController < ApplicationController

  before_filter :authenticate_user!
  def index
    @groups = current_user.groups
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new
    @group.owner = current_user
    @group.name = params[:group][:name]
    @group.users = params[:group][:users].split(/\W+/)
    @group.save!
    redirect_to groups_path, :notice=>"Group created"
  end
end
