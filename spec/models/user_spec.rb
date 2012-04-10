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
    @user.owned_groups.should == [g1, g2]
  end

  describe "#groups" do
    before do
      @group = FactoryGirl.build(:user_group)
      @user = FactoryGirl.create(:user)
      @group.users = [@user.email]
      @group.save
    end
    it "should return a list" do
      @user.groups.should == [@group]
    end
  end

  describe "#collections" do
    before :all do
      DILCollection.find(:all, :rows=>200).each do |d|
        d.delete
      end
    end
    before do
      @user = FactoryGirl.find_or_create(:archivist)
      @c1 = DILCollection.new
      @c1.apply_depositor_metadata(@user.uid)
      @c1.save!
        
      @c2 = DILCollection.new
      @c2.apply_depositor_metadata(@user.uid)
      @c2.save!

      @c3 = DILCollection.create #not mine
    end
    it "should return the list" do
      @user.collections.should == [{"id"=>@c1.pid}, {"id"=>@c2.pid}]
    end
  end

end
