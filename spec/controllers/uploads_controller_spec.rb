require 'spec_helper'

describe UploadsController do
  it "should route" do 
    {:get=>'/uploads'}.should route_to(:controller=>'uploads', :action=>'index')
    {:post=>'/uploads/create'}.should route_to(:controller=>'uploads', :action=>'create')
    {:post=>'/uploads/update_status'}.should route_to(:controller=>'uploads', :action=>'update_status')
    {:post=>'/uploads/enqueue'}.should route_to(:controller=>'uploads', :action=>'enqueue')
  end
  it "should have paths helpers" do
    uploads_create_path.should == '/uploads/create'
    enqueue_uploads_path.should == '/uploads/enqueue'
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
      @before_count = Multiresimage.count
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
      post :create, :files=>[fixture_file_upload('/images/The_Tilled_Field.jpg', 'image/jpeg')], :format=>:json
    end
    it "should create a new Multiresimage" do
      Multiresimage.count.should == @before_count + 1
    end
    it "should store uploaded files in session" do
      @user.upload_files.map(&:pid).should == [assigns[:image].pid]
    end
    it "should return JSON for jquery-file-uploader" do
      json = JSON.parse(response.body)
      json.size.should == 1
      json.first["name"].should == "The_Tilled_Field.jpg"
      json.first["size"].should == 98982
      json.first["delete_type"].should == "DELETE"
      json.first.should have_key "delete_url"
    end
    it "should set the mime type on the saved object" do
      obj = Multiresimage.find(assigns[:image].pid)
      obj.raw.mimeType.should == 'image/jpeg'
    end
    it "should set user metadata" do
      obj = Multiresimage.find(assigns[:image].pid)
      obj.rightsMetadata.individuals.should == {"archivist1"=>"edit"}
    end
  end

  describe "enqueue" do
    before do
      req1 = stub('request')
      req2 = stub('request')
      req1.should_receive(:enqueue)
      req2.should_receive(:enqueue)
      @user = FactoryGirl.find_or_create(:archivist)
      @img1 = Multiresimage.new(:pid=>'pid:one')
      @img2 = Multiresimage.new(:pid=>'pid:two')
      @img1.save
      @img2.save
      UploadFile.create(:pid=>'pid:one', :user=>@user)
      UploadFile.create(:pid=>'pid:two', :user=>@user)
      ImageProcessingRequest.should_receive(:create!).with(:status => 'NEW', :pid=>'pid:one', :email => 'm-stroming@northwestern.edu').and_return(req1)
      ImageProcessingRequest.should_receive(:create!).with(:status => 'NEW', :pid=>'pid:two', :email => 'm-stroming@northwestern.edu').and_return(req2)
      sign_in @user
      post :enqueue, :titleSet_display=>"The title"
    end
    it "should create one image_processing_request for ever file uploaded and enqueue it" do
      flash[:notice].should == "Your files are now being processed"
      response.should redirect_to(catalog_index_path)
    end
    it "should clear the files stored in the uploaded_files" do
      @user.upload_files.should == []
    end
    it "should add title to each batch image" do
      Multiresimage.find("pid:one").titleSet_display.should == "The title"
      Multiresimage.find("pid:two").titleSet_display.should == "The title"
    end
  end

  describe "update_status" do
    before do
      @image = Multiresimage.new
      @image.update_attributes(:file_name =>'foo.jpg')
      @req = ImageProcessingRequest.create!(:pid=>@image.pid, :email=>'test@example.com', :status=>'NEW')
    end
    it "should update the record" do
       post :update_status, :request_id =>@req.id, :image_path=>'', :width=>'w', :height=>'', :status=>"OK"
       req = ImageProcessingRequest.find(@req.id)
       req.status.should == "VALIDATEDOK"
    
       response.should be_success
    end
  end
end
