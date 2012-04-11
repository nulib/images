require 'spec_helper'

describe DilCollectionsController do
  describe "#create" do
    describe "as a logged in user" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
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
