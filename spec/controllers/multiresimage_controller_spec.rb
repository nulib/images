require 'spec_helper'

describe MultiresimagesController do
  describe "destroy" do
    before do
      @img = Multiresimage.create
      @user = FactoryGirl.find_or_create(:archivist)
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
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
    end
    describe "that I have edit permissions on" do
      before do
        @img.apply_depositor_metadata(@user.uid)
        @img.save
      end
      it "should save changes" do
        put :update, :id=>@img.pid, :titleSet_display =>"New title"
        response.should redirect_to(edit_multiresimage_path(@img))
        assigns[:multiresimage].titleSet_display.should == "New title"
        flash[:notice].should == "Saved changes to #{@img.pid}"
      end
    end
    describe "that I don't have edit permissions on" do
      it "should redirect to catalog" do
        put :update, :id=>@img.pid
        response.should redirect_to(root_path)
        flash[:alert].should == 'You are not authorized to access this page.'
      end
    end
    # subject do
    #   m = Multiresimage.new()
    #   @u = 
    #   @g1 = FactoryGirl.create(:user_group, :owner=>@u)
    #   @g2 = FactoryGirl.create(:user_group)
    #   m.rightsMetadata.update_permissions("person"=>{"person1"=>"read","person2"=>"discover"}, "group"=>{"group-7"=>'read', 'group-8'=>'edit'})
    #   m.save
    #   m
    # end
    # it "should have read groups accessor" do
    #   subject.read_groups.should == ['group-7']
    # end
    # it "should have read groups writer" do
    #   subject.read_groups = ['group-2', 'group-3']
    #   subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
    #   subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    # end
    # it "should not remove groups owned by other users"
  end

end
