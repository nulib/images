require 'spec_helper'

describe PermissionsHelper do
  describe "sort_permissions" do
    it "should sort the permissions by name (user/group id)" do
      permissions_array = [{:type=>"group", :access=>"discover", :name=>"xstudents"}, {:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}]
      sort_permissions(permissions_array).should == [{:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}, {:type=>"group", :access=>"discover", :name=>"xstudents"}]
    end
  end
  describe "permissions_users" do
    it "should sort the permissions by name (user/group id)" do
      permissions_array = [{:type=>"group", :access=>"discover", :name=>"xstudents"}, {:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}]
      obj = stub("Object", :permissions=>permissions_array)
      permissions_users(obj).should == [{:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}]
    end
  end
  describe "permissions_groups" do
    it "should sort the permissions by name (user/group id)" do
      permissions_array = [{:type=>"group", :access=>"discover", :name=>"xstudents"}, {:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}]
      obj = stub("Object", :permissions=>permissions_array)
      permissions_groups(obj).should == [{:type=>"group", :access=>"discover", :name=>"xstudents"}]
    end
  end
  
end