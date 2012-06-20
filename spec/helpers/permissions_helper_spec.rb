require 'spec_helper'

describe PermissionsHelper do
  describe "sort_permissions" do
    it "should sort the permissions by name (user/group id)" do
      permissions_array = [{:type=>"group", :access=>"discover", :name=>"xstudents"}, {:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}]
      sort_permissions(permissions_array).should == [{:type=>"user", :access=>"read", :name=>"auser5566"}, {:type=>"user", :access=>"edit", :name=>"vanessa"}, {:type=>"group", :access=>"discover", :name=>"xstudents"}]
    end
  end
end