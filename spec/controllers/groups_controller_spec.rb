require 'spec_helper'

describe GroupsController do

  describe "#index" do
    describe "when logged in" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        sign_in @user
        # owned by me
        @g1 = FactoryGirl.create(:user_group, :owner=>@user)
        # not owned by me
        @g2 = FactoryGirl.create(:user_group)
        ## This represents a system group (e.g. no owner)
        @g3 = FactoryGirl.create(:user_group, :owner=>nil)
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
        post :create, :group=>{:name=>'my group', :users_text=>'justin alicia,eddie'}
        assigns[:group].users.should == ['justin', 'alicia', 'eddie']
        flash[:notice].should == "Group created"
        response.should redirect_to(groups_path)
      end
      it "should handle errors" do
        post :create, :group=>{:name=>'', :users_text=>'justin alicia,eddie'}
        assigns[:group].users.should == ['justin', 'alicia', 'eddie']
        assigns[:group].users_text.should == 'justin alicia,eddie'
        assigns[:group].errors[:name].should == ["can't be blank"]
        response.should be_success
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
