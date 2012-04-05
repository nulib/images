require 'spec_helper'

describe User do
  it "should require an email" do
    u = User.new
    u.save.should be_false
    u.errors[:email].should == ["can't be blank"] 
  end
  it "should require a password" do
    u = User.new
    u.save.should be_false
    u.errors[:password].should == ["can't be blank"] 
  end
end
