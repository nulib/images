require 'spec_helper'

describe PoliciesController do
  describe "edit" do
    before do
      @policy = AdminPolicy.create
    end
    after do
      @policy.delete
    end
    describe "by someone who is not authoized" do
      before do
        @policy.save
      end
      it "should say not authorized" do
        get :edit, :id => @policy.pid
        assigns["policy"].should == @policy
        response.should redirect_to root_path
        flash[:alert].should == "You are not authorized to access this page."
      end
    end
    describe "by someone who is authorized" do
      before do
        @policy.edit_groups = ['staff']
        @policy.save
        @user = FactoryGirl.find_or_create(:staff)
        Hydra::LDAP.stub(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      it "should show the edit form" do
        get :edit, :id => @policy.pid
        assigns["policy"].should == @policy
        response.should be_successful
      end
    end
  end

  describe "new" do
    it "should draw the form" do
        get :new
        assigns["policy"].should be_kind_of AdminPolicy
        response.should be_successful
    end
  end

end
