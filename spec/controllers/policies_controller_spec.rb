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

  describe "as the archivist" do

    before do
      @policy = AdminPolicy.create
      @user = FactoryGirl.find_or_create(:archivist)
      Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
      sign_in @user
    end
    describe "new" do
      it "should draw the form" do
        get :new
        assigns["policy"].should be_kind_of AdminPolicy
        response.should be_successful
      end
    end

    describe "create" do
      it "should save the new policy and creator should have edit perms" do
        post :create, :admin_policy=>{:title=>'My title'}
        response.should redirect_to policies_path
        assigns['policy'].title.should == 'My title'
        assigns["policy"].edit_users.should == ['archivist1']
      end
    end

    describe "update" do
      describe "that I have edit permissions on" do
        before do
          @policy.apply_depositor_metadata(@user.uid)
          @policy.edit_groups = ["staff"]
          @policy.save
        end
        it "should save changes to the policy" do
          put :update, :id=>@policy.pid, :admin_policy=>{:title =>"New title"}
          response.should redirect_to(policies_path())
          assigns[:policy].title.should == "New title"
          flash[:notice].should == "Saved changes to New title"
        end
        
        describe "setting permissions" do
          it "should update permissions" do
            put :update, :id=>@policy.pid, :admin_policy=>{"permissions"=>{"group"=>{"staff"=>"edit", "faculty"=>"edit"}, "user"=>{"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read"}, 
            "new_group_name"=>"", "new_group_permission"=>"none", 
            "new_user_name"=>"", "new_user_permission"=>"none"},
            "default_permissions"=>{"group"=>{"staff"=>"edit", "faculty"=>"edit"}, "user"=>{"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read"}, 
            "new_group_name"=>"", "new_group_permission"=>"none", 
            "new_user_name"=>"", "new_user_permission"=>"none"}}
            updated_policy = AdminPolicy.find(@policy.pid)
            updated_policy.edit_groups.should include("staff")
            updated_policy.edit_groups.should include("faculty") 
            updated_policy.discover_users.should include("student1")
            updated_policy.edit_users.should include("vanessa")
            updated_policy.read_users.should include("archivist1")
            updated_policy.defaultRights.individuals.should == {"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read"}
          end
          it "should add group & user permissions without wiping out existing permissions" do
            # pre-existing permissions
            @policy.edit_groups.should include("staff") 
            @policy.edit_users.should include(@user.uid)
            
            put :update, :id=>@policy.pid, :admin_policy=>{"permissions"=>{
              "new_group_name"=>"mynewgroup", "new_group_permission"=>"discover", 
              "new_user_name"=>"uuuusssserzed", "new_user_permission"=>"edit"}}
            updated_policy = AdminPolicy.find(@policy.pid)
            # check that new permissions were granted
            updated_policy.discover_groups.should include("mynewgroup")
            updated_policy.edit_users.should include("uuuusssserzed")
            # check that the original permissions weren't changed
            updated_policy.edit_groups.should include("staff") 
            updated_policy.edit_users.should include(@user.uid)
          end
        end
      end
    end
  end

  describe "index" do
    it "should be successful" do
      get :index
      response.should be_successful
      assigns[:policies].should be_kind_of Array
    end
    it "should only have policies that you have the ability to view"
  end
end
