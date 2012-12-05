require 'spec_helper'

describe DilCollectionsController do
  before do
    Group.any_instance.stub :persist_to_ldap
  end
  describe "#add an image to the collection" do
    describe "as a logged in user with edit permission on the collection and read on the image" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        @collection = FactoryGirl.build(:collection)
        @collection.save!
        @collection.edit_users = [@user.uid]
        @collection.save!
        @img = Multiresimage.find('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
        @img.titleSet_display = "foo"
        @img.save!
        Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      it "should be successful" do
        post :add, :id=>@collection.pid, :member_id=>@img.pid
        response.should be_success
        assigns[:collection].members.mods.title_info.main_title.should == ['foo']
        assigns[:collection].members.mods.relatedItem.identifier.should == ['inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26']
        Multiresimage.find(@img.pid).collection_ids.should include assigns[:collection].pid
        
      end
    end
  end
  describe "#create" do
    describe "as a logged in user" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        stub_groups_for_user @user
        sign_in @user
      end
      it "should be successful" do
        post :create, :dil_collection=>{:title=>'Oarsman'}
        assigns[:dil_collection].title.should == 'Oarsman'
        assigns[:dil_collection].should_not be_new_record
        response.should redirect_to(catalog_index_path)
      end
    end
    describe "when not logged in" do
      it "should redirect" do
        post :create, :dil_collection=>{:title=>'Oarsman'}
        assigns[:dil_collection].should be_nil
        response.should redirect_to(root_path)
        flash[:alert].should == "You are not authorized to access this page."
      end
    end
  end
  describe "#edit" do
    before do
      @collection = FactoryGirl.create(:collection)
    end
    describe "as a logged in user" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      describe "when I am authorized to edit" do
        before do
          @collection.apply_depositor_metadata(@user.uid)
          @collection.save!
        end
        it "should be successful" do
          get :edit, :id=>@collection.pid
          response.should be_success
          assigns[:collection].should be_kind_of DILCollection
        end
      end
      describe "when I am not authorized" do
        it "should redirect" do
          get :edit, :id=>@collection.pid
          response.should redirect_to(root_path)
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end
    describe "when not logged in" do
      it "should redirect" do
        get :edit, :id=>@collection.pid
        response.should redirect_to(root_path)
        flash[:alert].should == "You are not authorized to access this page."
      end
    end
  end

  describe "#update" do
    before do
      @collection = FactoryGirl.create(:collection)
    end
    describe "as a logged in user" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      describe "when I am authorized to update" do
        before do
          @collection.apply_depositor_metadata(@user.uid)
          @collection.save!
        end
        it "should be successful" do
          put :update, :id=>@collection.pid, :dil_collection=>{:title=>'New title'}
          response.should redirect_to(edit_dil_collection_path(@collection))
          assigns[:collection].title.should == "New title"
          flash[:notice].should == "Saved changes to New title"
        end
        describe "setting group access" do
          before do
            @g1 = FactoryGirl.create(:user_group, :owner=>@user)
            @g2 = FactoryGirl.create(:user_group, :owner=>@user)
            @g3 = FactoryGirl.create(:user_group)
            @collection.read_groups = [@g1.code, @g3.code]
            @collection.save!
            Hydra::LDAP.stub(:groups_owned_by_user).with(@user.uid).and_return([@g1.code, @g2.code])
            put :update, :id=>@collection.pid, :dil_collection=>{:read_groups =>[@g2.code]}
          end
          it "should set read access to groups I specify and not remove groups that I don't own" do
            assigns[:collection].read_groups.should == [@g3.code, @g2.code]
          end
        end
      end
      describe "when I am not authorized" do
        it "should redirect" do
          put :update, :id=>@collection.pid
          response.should redirect_to(root_path)
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end
    describe "when not logged in" do
      it "should redirect" do
        put :update, :id=>@collection.pid
        response.should redirect_to(root_path)
        flash[:alert].should == "You are not authorized to access this page."
      end
    end
  end
end
