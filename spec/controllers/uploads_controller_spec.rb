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
    it "should respond to html" do
      get :index
      response.should be_success
    end
    it "should respond to json" do
      get :index, :format=>:json
      json = JSON.parse(response.body)
      json.should == []
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
      json.size.should == 1
      json.first["name"].should == "The_Tilled_Field.jpg"
      json.first["size"].should == 98982
      json.first["delete_type"].should == "DELETE"
      json.first.should have_key "delete_url"
      pid = json.first["delete_url"].sub(/^\/\w+\//, '')
      Multiresimage.count.should == before_count + 1
      obj = Multiresimage.find(pid)
      obj.raw.mimeType.should == 'image/jpeg'
      session[:files].should == [pid]
      
    end
  end
end
