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
    before do
      sign_in FactoryGirl.find_or_create(:archivist)
    end
    it "should be successful" do
      get :index
      response.should be_success
    end
  end

  describe "create" do
    before do
      sign_in FactoryGirl.find_or_create(:archivist)
    end
    it "should store uploaded files and return JSON" do
      before_count = Multiresimage.count
      session[:files].should be_nil
      post :create, :files=>[fixture_file_upload('/images/The_Tilled_Field.jpg', 'image/jpeg')], :format=>:json
      
      json = JSON.parse(response.body)
      json["name"].should == "The_Tilled_Field.jpg"
      json["size"].should == 98982
      json["delete_type"].should == "DELETE"
      json.should have_key "delete_url"
      Multiresimage.count.should == before_count + 1
      
    end
  end
end
