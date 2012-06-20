require 'spec_helper'

describe MultiresimagesController do
  before do
    Group.any_instance.stub :persist_to_ldap
  end
  describe "destroy" do
    before do
      @img = Multiresimage.create
      @user = FactoryGirl.find_or_create(:archivist)
      Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
      sign_in @user
    end
    describe "an image that I have edit permissions on" do
      before do
        @img.apply_depositor_metadata(@user.uid)
        @img.save
      end
      it "should be destroyed" do
        delete :destroy, :id=>@img.pid
        Multiresimage.exists?(@img.pid).should be_false
        flash[:notice].should == "Image has been deleted"
        response.should redirect_to(catalog_index_path)
      end
      it "should be removed from the session too"do
        session[:files] = [@img.pid]
        delete :destroy, :id=>@img.pid
        session[:files].should == []
      end
    end
    describe "an image that I don't have edit permissions on" do
      it "should not be destroyed" do
        delete :destroy, :id=>@img.pid
        Multiresimage.exists?(@img.pid).should be_true
      end
    end
  end

  describe "edit an image" do
    before do
      @img = Multiresimage.create
      @user = FactoryGirl.find_or_create(:archivist)
      Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
      sign_in @user
    end
    describe "that I have edit permissions on" do
      before do
        @img.apply_depositor_metadata(@user.uid)
        @img.save
      end
      it "should be success" do
        get :edit, :id=>@img.pid
        assigns[:multiresimage].should == @img
        response.should be_success
      end
    end
    describe "that I don't have edit permissions on" do
      it "should redirect to catalog" do
        get :edit, :id=>@img.pid
        response.should redirect_to(root_path)
        flash[:alert].should == 'You are not authorized to access this page.'
      end
    end
  end
  describe "update an image" do
    before do
      @img = Multiresimage.create
      @work = Vrawork.create
      @img.vraworks = [@work]
      @user = FactoryGirl.find_or_create(:archivist)
      Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
      sign_in @user
    end
    describe "that I have edit permissions on" do
      before do
        @img.apply_depositor_metadata(@user.uid)
        @img.edit_groups = ["staff"]
        @img.save
      end
      it "should save changes to the image and its associated vrawork" do
        put :update, :id=>@img.pid, :multiresimage=>{:titleSet_display =>"New title"}
        response.should redirect_to(edit_multiresimage_path(@img))
        assigns[:multiresimage].titleSet_display.should == "New title"
        assigns[:multiresimage].vraworks.first.titleSet_display_work.should == "New title"
        flash[:notice].should == "Saved changes to #{@img.pid}"
      end
      
      describe "setting permissions" do
        it "should update permissions" do
          put :update, :id=>@img.pid, :multiresimage=>{"permissions"=>{"group"=>{"staff"=>"edit", "faculty"=>"edit"}, "user"=>{"student1"=>"discover","vanessa"=>"edit", "archivist1"=>"read"}, 
          "new_group_name"=>"", "new_group_permission"=>"none", 
          "new_user_name"=>"", "new_user_permission"=>"none"}}
          updated_img = Multiresimage.find(@img.pid)
          updated_img.edit_groups.should include("staff")
          updated_img.edit_groups.should include("faculty") 
          updated_img.discover_users.should include("student1")
          updated_img.edit_users.should include("vanessa")
          updated_img.read_users.should include("archivist1")
        end
        it "should add group & user permissions without wiping out existing permissions" do
          # pre-existing permissions
          @img.edit_groups.should include("staff") 
          @img.edit_users.should include(@user.uid)
          
          put :update, :id=>@img.pid, :multiresimage=>{"permissions"=>{
            "new_group_name"=>"mynewgroup", "new_group_permission"=>"discover", 
            "new_user_name"=>"uuuusssserzed", "new_user_permission"=>"edit"}}
          updated_img = Multiresimage.find(@img.pid)
          # check that new permissions were granted
          updated_img.discover_groups.should include("mynewgroup")
          updated_img.edit_users.should include("uuuusssserzed")
          # check that the original permissions weren't changed
          updated_img.edit_groups.should include("staff") 
          updated_img.edit_users.should include(@user.uid)
        end
      end

      describe "setting group access" do
        before do
          @g1 = FactoryGirl.create(:user_group, :owner=>@user)
          @g2 = FactoryGirl.create(:user_group, :owner=>@user)
          @g3 = FactoryGirl.create(:user_group)
          @img.read_groups = [@g1.code, @g3.code]
          @img.save!
          Hydra::LDAP.stub(:groups_owned_by_user).with(@user.uid).and_return([@g1.code, @g2.code])
          put :update, :id=>@img.pid, :multiresimage=>{:read_groups =>[@g2.code]}
        end
        it "should set read access to groups I specify and not remove groups that I don't own" do
          assigns[:multiresimage].read_groups.should == [@g3.code, @g2.code]
        end
      end
    end
    describe "that I don't have edit permissions on" do
      it "should redirect to catalog" do
        put :update, :id=>@img.pid
        response.should redirect_to(root_path)
        flash[:alert].should == 'You are not authorized to access this page.'
      end
    end
  end
  
  describe "parse_permissions" do
    it "should take post params and turn them into a hash that works with Hydra::ModelMixins::RightsMetadata#permissions=" do
      permissions_params = {"new_user_name"=>"mzc206", "new_user_permission"=>"read", "new_group_name"=>"grp108", "new_group_permission"=>"edit", "group"=>{"group22"=>"discover", "group65"=>"read"}, "user"=>{"jcoyne"=>"edit", "acozine"=>"read"}}
      sample_params = {:generic_file=>{:permissions=>permissions_params, :otherkey=>"otherval"}}
      result = controller.send(:parse_permissions!, sample_params[:generic_file])
      result.should == sample_params[:generic_file] # it should modify the source hash
      sample_params[:generic_file][:permissions].should == [{:name=>"mzc206", :access=>"read", :type=>"user"}, {:name=>"grp108", :access=>"edit", :type=>"group"}, {:name=>"jcoyne", :access=>"edit", :type=>"user"}, {:name=>"acozine", :access=>"read", :type=>"user"}, {:name=>"group22", :access=>"discover", :type=>"group"}, {:name=>"group65", :access=>"read", :type=>"group"}]
      sample_params[:generic_file][:otherkey].should == "otherval"
    end
    
  end

end
