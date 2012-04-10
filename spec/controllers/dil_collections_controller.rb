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
end
