require 'spec_helper'

describe UsersController do
  before do
    Group.any_instance.stub :persist_to_ldap
  end

  describe "#create" do
    describe "when logged in" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        Dil::LDAP.stub(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      describe "on a group the user owns" do
        before do
          @group= FactoryGirl.create(:user_group, :owner=>@user)
          Dil::LDAP.should_receive(:owner_for_group).with(@group.code).and_return(@user.uid)
          Dil::LDAP.should_receive(:add_users_to_group).with(@group.code, ['ken']).and_return(true)
        end
        it "should be successful" do
          post :create, :id=>'ken', :group_id=>@group.id
          flash[:notice].should == "Added member ken"
          response.should redirect_to(edit_group_path(@group))
        end
      end
      describe "without a group" do
        it "should handle errors" do
          post :create, :id=>'ken'
          response.response_code.should == 404
        end
      end
      describe "on a group the user doesn't own" do
        before do
          @group= FactoryGirl.create(:user_group)
          Dil::LDAP.should_receive(:owner_for_group).with(@group.code).and_return(@group.owner_uid)
        end
        it "should handle errors" do
          post :create, :id=>'ken', :group_id=>@group.id
          response.should redirect_to(root_path)
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end
    describe "when not logged in" do
      before do
        @group= FactoryGirl.create(:user_group)
      end
      it "should redirect to signin" do
        post :create, :id=>'ken', :group_id=>@group.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end
  describe "#destroy" do
    describe "when logged in" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        Dil::LDAP.stub(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      describe "on a group the user owns" do
        before do
          @group= FactoryGirl.create(:user_group, :owner=>@user)
          Dil::LDAP.should_receive(:owner_for_group).with(@group.code).and_return(@user.uid)
          Dil::LDAP.should_receive(:remove_users_from_group).with(@group.code, ['ken']).and_return(true)
        end
        it "should be successful" do
          delete :destroy, :id=>'ken', :group_id=>@group.id
          flash[:notice].should == "Removed member ken"
          response.should redirect_to(edit_group_path(@group))
        end
      end
      describe "without a group" do
        it "should handle errors" do
          delete :destroy, :id=>'ken'
          response.response_code.should == 404
        end
      end
      describe "on a group the user doesn't own" do
        before do
          @group= FactoryGirl.create(:user_group)
          Dil::LDAP.should_receive(:owner_for_group).with(@group.code).and_return(@group.owner_uid)
          Dil::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([@group])
        end
        it "should handle errors" do
          delete :destroy, :id=>'ken', :group_id=>@group.id
          response.should redirect_to(root_path)
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end
    describe "when not logged in" do
      before do
        @group= FactoryGirl.create(:user_group)
      end
      it "should redirect to signin" do
        delete :destroy, :id=>'ken', :group_id=>@group.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end
end
