require 'spec_helper'

describe GroupsController do

  describe "#index" do
    describe "when logged in" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        sign_in @user
        @g1 = Group.create!(:owner=>@user, :name=>'foo')
        @g2 = Group.create!(:owner=>User.create, :name=>'bar')
        @g3 = Group.create!(:name=>'bax')
      end
      it "should be successful" do
        get :index
        assigns[:groups].should be_kind_of Array
        assigns[:groups].should include @g1
        assigns[:groups].should_not include @g2
        assigns[:groups].should_not include @g3
        response.should be_success
      end
    end
  end
  describe "#new" do
    describe "when logged in" do
      before do
        sign_in FactoryGirl.find_or_create(:archivist)
      end
      it "should be successful" do
        get :new
        assigns[:group].should be_kind_of Group
        response.should be_success
      end
    end
  end
  describe "#create" do
    describe "when logged in" do
      before do
        sign_in FactoryGirl.find_or_create(:archivist)
      end
      it "should be successful" do
        post :create, :group=>{:name=>'my group', :users=>'justin alicia,eddie'}
        assigns[:group].users.should == ['justin', 'alicia', 'eddie']
        flash[:notice].should == "Group created"
        response.should redirect_to(groups_path)
      end
    end
    describe "when not logged in" do
      it "should redirect to signin" do
        post :create, :group=>{:name=>'my group', :users=>'justin alicia,eddie'}
        response.should redirect_to(new_user_session_path)
      end
    end
  end

end
