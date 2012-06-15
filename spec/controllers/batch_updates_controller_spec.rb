require 'spec_helper'

describe BatchUpdatesController do
  before(:each) do
    request.env["HTTP_REFERER"] = "/"
  end
  
  it "should add items to list" do
    @mock_response = mock()
    @mock_document = mock()
    @mock_document2 = mock()
    @mock_document.stub(:export_formats => {})
    controller.stub(:get_solr_response_for_field_values => [@mock_response, [@mock_document, @mock_document2]])

    put :add, :id =>"77826928"
    session[:batch_document_ids].length.should == 1
    put :add, :id => "94120425"
    session[:batch_document_ids].length.should == 2
    session[:batch_document_ids].should include("77826928")
    get :index
    assigns[:documents].length.should == 2
    assigns[:documents].first.should == @mock_document
  end
  it "should delete an item from list" do
    put :add, :id =>"77826928"
    put :add, :id => "94120425"
    delete :destroy, :id =>"77826928"
    session[:batch_document_ids].length.should == 1
    session[:batch_document_ids].should_not include("77826928")
  end
  it "should clear list" do
    put :add, :id =>"77826928"
    put :add, :id => "94120425"
    put :clear
    session[:batch_document_ids].length.should == 0
  end

  it "should generate flash messages for normal requests" do
    put :add, :id => "77826928"
    flash[:notice].length.should_not == 0
  end
  it "should clear flash messages after xhr request" do
    xhr :put, :add, :id => "77826928"
    flash[:notice].should == nil
  end

  describe "edit" do
    before do
      @one = Multiresimage.new
      @two = Multiresimage.new
      @user = FactoryGirl.find_or_create(:archivist)
      @one.apply_depositor_metadata(@user.uid)
      @one.save
      @two.apply_depositor_metadata(@user.uid)
      @two.save
      sign_in @user
    end
    it "should draw the form" do
      put :add, :id =>@one.pid
      put :add, :id =>@two.pid
      get :edit
      response.should be_successful
      
    end
  end


  describe "update" do
    before :all do
      @one = Multiresimage.create
      @two = Multiresimage.create
    end
    it "should complain when none are in the batch " do
      put :update, :multiresimage=>{:titleSet_display=>'My title' } 
      response.should redirect_to catalog_index_path
      flash[:notice].should == "Select something first"
    end
    it "should not update when the user doesn't have permissions" do
      put :add, :id =>@one.pid
      put :add, :id => @two.pid
      put :update, :multiresimage=>{:titleSet_display=>'My title' } 
      response.should redirect_to catalog_index_path
      flash[:notice].should == "You do not have permission to edit the documents: #{@one.pid}, #{@two.pid}"
    end
    describe "when current user has access to the documents" do
      before do
        @user = FactoryGirl.find_or_create(:archivist)
        @one.apply_depositor_metadata(@user.uid)
        @one.save
        @two.apply_depositor_metadata(@user.uid)
        @two.save
        put :add, :id =>@one.pid
        put :add, :id => @two.pid
        sign_in @user
      end
      it "should update all the field" do
        put :update, :multiresimage=>{:titleSet_display=>'My title' } 
        response.should redirect_to catalog_index_path
        flash[:notice].should == "Batch update complete"
        Multiresimage.find(@one.pid).titleSet_display.should == "My title"
      end
    end
  end


  describe "state" do
    it "should save state on" do
      xhr :put, :state, :state=>'on'
      response.should be_successful
      session[:batch_update_state].should == 'on'
    end
    it "should save state off" do
      xhr :put, :state, :state=>'off'
      response.should be_successful
      session[:batch_update_state].should == 'off'
    end
  end


end
