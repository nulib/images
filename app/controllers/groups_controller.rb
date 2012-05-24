class GroupsController < ApplicationController

  before_filter :authenticate_user!
  def index
    @groups = current_user.owned_groups
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new
    @group.owner = current_user
    @group.name = params[:group][:name]
    @group.users_text = params[:group][:users_text]
    @group.users = @group.users_text.split(/\W+/)
    if @group.save
      redirect_to groups_path, :notice=>"Group created"
    else
      render :new
    end
  end

  def edit
    @group = Group.find(params[:id])
    authorize! :edit, @group
    
  end
end
