require 'spec_helper'

describe UploadsController do
  it "should route" do 
    {:get=>'/uploads'}.should route_to(:controller=>'uploads', :action=>'index')
    {:post=>'/uploads/create'}.should route_to(:controller=>'uploads', :action=>'create')
    {:get=>'/uploads/test'}.should route_to(:controller=>'uploads', :action=>'test')
    {:post=>'/uploads/update_status'}.should route_to(:controller=>'uploads', :action=>'update_status')
  end
  it "should have paths helpers" do
    uploads_create_path.should == '/uploads/create'
    uploads_path.should == '/uploads'
  end

  describe "index" do
    it "should be successful" do
      get :index
      response.should be_success
    end
  end
end
