require 'spec_helper'

describe "Routes for batch_update" do
  it "should route index" do 
    { :get => '/batch_updates' }.should route_to( :controller => "batch_updates", :action => "index")
  end
  it "should route edit" do 
    { :get => edit_batch_updates_path }.should route_to( :controller => "batch_updates", :action => "edit")
  end
  it "should route update" do 
    { :put => batch_updates_path }.should route_to( :controller => "batch_updates", :action => "update")
  end
  it "should route add" do 
    { :put => '/batch_updates/7'}.should route_to( :controller => "batch_updates", :action => "add", :id=>'7')
  end
  it "should route delete" do 
    { :delete => '/batch_updates/7' }.should route_to( :controller => "batch_updates", :action => "destroy", :id=>'7')
    batch_update_path(7).should == "/batch_updates/7"
  end


end
