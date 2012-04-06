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

  it "should have many groups that they own" do
    @user = FactoryGirl.find_or_create(:archivist)
    g1 = Group.new(:name=>'one')
    g1.owner = @user
    g1.save!
    g2 = Group.new(:name=>'two')
    g2.owner = @user
    g2.save!
    g3 = Group.new(:name=>'three')
    g3.owner = FactoryGirl.create(:user)
    g3.save!
    @user.groups.should == [g1, g2]
  end

end
