require 'spec_helper'

describe PoliciesController do
  pending("Pending the addition of Policies") do
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
        post :create, :admin_policy=>{:title=>'My title', "permissions"=>{"new_user_name"=>"justin", "new_user_permission"=>"edit", "new_group_name"=>"", "new_group_permission"=>"none"}}
        response.should redirect_to policies_path
        assigns['policy'].title.should == 'My title'
        assigns["policy"].edit_users.should == ['archivist1', 'justin']
      end
    end

    describe "update" do
      describe "that I have edit permissions on" do
        before do
          @policy.apply_depositor_metadata(@user.uid)
          @policy.edit_groups = ["staff"]
          @policy.rightsMetadata.permissions({:person=>"jason"}, "edit") #depositor metadata already set, don't overwrite.
          @policy.default_permissions =  [{:name=>"marcus", :access=>"discover", :type=>'user'}, {:name=>"group1", :access=>"edit", :type=>'group'}]
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
            "new_read_group_name"=>"", "new_edit_group_name"=>"", "new_read_user_name"=>"", "new_edit_user_name"=>""},
            "default_permissions"=>{"group"=>{"staff"=>"edit", "faculty"=>"edit"}, "user"=>{"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read"}, 
            "new_group_name"=>"", "new_group_permission"=>"none", 
            "new_user_name"=>"", "new_user_permission"=>"none"}}
            updated_policy = AdminPolicy.find(@policy.pid)
            updated_policy.edit_groups.should include("staff")
            updated_policy.edit_groups.should include("faculty") 
            updated_policy.discover_users.should include("student1")
            updated_policy.edit_users.should include("vanessa")
            updated_policy.read_users.should include("archivist1")
            updated_policy.defaultRights.individuals.should == {"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read", 'marcus'=>'discover'}
          end
          it "should add group & user permissions without wiping out existing permissions" do
            # pre-existing permissions
            @policy.edit_groups.should include("staff") 
            @policy.edit_users.should include(@user.uid)
            
            put :update, :id=>@policy.pid, :admin_policy=>{"permissions"=>{
              "new_read_group_name"=>"mynewgroup", "new_edit_group_name"=>"",
              "new_read_user_name"=>"", "new_edit_user_name"=>"uuuusssserzed"}}
            updated_policy = AdminPolicy.find(@policy.pid)
            # check that new permissions were granted
            updated_policy.read_groups.should include("mynewgroup")
            updated_policy.edit_users.should include("uuuusssserzed")
            # check that the original permissions weren't changed
            updated_policy.edit_groups.should include("staff") 
            updated_policy.edit_users.should include(@user.uid)
          end
          it "should add group & user default permissions without wiping out existing default permissions" do
            # pre-existing permissions
            @policy.default_permissions.should include({:name=>"marcus", :access=>"discover", :type=>'user'})
            @policy.default_permissions.should include({:name=>"group1", :access=>"edit", :type=>'group'})
            
            put :update, :id=>@policy.pid, :admin_policy=>{
              "default_permissions"=>{"group"=>{"staff"=>"edit", "faculty"=>"edit"}, "user"=>{"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read"}, 
            "new_group_name"=>"group3", "new_group_permission"=>"edit", 
            "new_user_name"=>"student2", "new_user_permission"=>"view"}}
            updated_policy = AdminPolicy.find(@policy.pid)
            # check that new permissions were granted
            updated_policy.default_permissions.should ==  [{:type=>"group", :access=>"edit", :name=>"group1"},
              {:type=>"group", :access=>"edit", :name=>"group3"},
              {:type=>"group", :access=>"edit", :name=>"staff"},
              {:type=>"group", :access=>"edit", :name=>"faculty"},
              {:type=>"user", :access=>"discover", :name=>"marcus"},
              {:type=>"user", :access=>"discover", :name=>"student1"},
              {:type=>"user", :access=>"read", :name=>"archivist1"},
              {:type=>"user", :access=>"edit", :name=>"vanessa"}]
          end
          it "should not downgrade access" do
            xhr :put, :update, :id=>@policy.pid, :admin_policy=>{"permissions"=>{ 
              "new_read_group_name"=>"staff", "new_edit_group_name"=>"",
              "new_read_user_name"=>"jason", "new_edit_user_name"=>""}},
              :format=>'json'
            updated_policy = AdminPolicy.find(@policy.pid)
            updated_policy.edit_groups.should include("staff")
            updated_policy.edit_users.should include("jason")
            JSON.parse(response.body).should == {'errors' => ["jason is a maintainer.  Maintainers can already use the policy.", "staff is a maintainer.  Maintainers can already use the policy."] } 
          end
          describe "ajax requests" do
            it "should update view permissions" do
              xhr :put, :update, :id=>@policy.pid, :admin_policy=>{:permissions=>{:new_read_group_name=>"ajaxgroup"}}, :format=>'json'
              response.should be_successful
              JSON.parse(response.body).should == {'values'=>[{'name'=>'ajaxgroup', 'type'=>'group', 'access'=>'read'} ] }
            end
            it "should update edit permissions" do
              xhr :put, :update, :id=>@policy.pid, :admin_policy=>{:permissions=>{:new_edit_group_name=>"ajaxgroup"}}, :format=>'json'
              response.should be_successful
              JSON.parse(response.body).should == {'values'=>[{'name'=>'ajaxgroup', 'type'=>'group', 'access'=>'edit'} ]  }
            end
            it "should update provided permissions" do
              xhr :put, :update, :id=>@policy.pid, :admin_policy=>{:default_permissions=>{:new_group_name=>"ajaxgroup", :new_group_permission=>'read'}}, :format=>'json'
              response.should be_successful
              JSON.parse(response.body).should == {'values' => [{'name'=>'ajaxgroup', 'type'=>'group', 'access'=>'read'} ] } 
            end
          end   
        end
      end
    end
  end

  describe "index" do
    before  do
      @user = FactoryGirl.find_or_create(:staff)
      Hydra::LDAP.stub(:groups_for_user).with(@user.uid).and_return([])

      @user_policy = AdminPolicy.new
      @user_policy.edit_users = [@user.user_key]
      @user_policy.save
      @group_policy = AdminPolicy.new
      @group_policy.edit_groups = ['staff']
      @group_policy.save

      @readable_policy = AdminPolicy.new
      @readable_policy.read_groups = ['staff']
      @readable_policy.save

      @no_access_policy = AdminPolicy.create

      sign_in @user
    end
    after do
      @user_policy.delete
      @group_policy.delete
      @readable_policy.delete
      @no_access_policy.delete
    end
    it "should only have policies that you have the ability to view" do
      get :index
      response.should be_successful
      assigns[:edit_policies].should be_kind_of Array
      assigns[:read_policies].should be_kind_of Array
      edit_policy_pids = assigns[:edit_policies].map {|p| p["id"]}
      read_policy_pids = assigns[:read_policies].map {|p| p["id"]}
      read_policy_pids.should == [@readable_policy.pid]
      edit_policy_pids.should include(@user_policy.pid, @group_policy.pid)
      edit_policy_pids.should_not include(@no_access_policy.pid)
    end
  end end
end
