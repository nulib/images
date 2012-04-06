require 'spec_helper'

describe Group do
  describe "an instance" do
    subject { Group.new }
    describe "with an owner and name" do
      before do
        @u = FactoryGirl.find_or_create(:archivist)
        subject.owner = @u
        subject.name = "My Group"
      end
      its(:owner) { should == @u} 
      its(:name) { should == "My Group"} 
    end
    describe "without a name" do
      it "should require a name" do
        subject.save.should be_false
        subject.errors[:name].should == ["can't be blank"]
      end
    end
    describe "with users" do
      subject do
        g = Group.new(:name=>"My Group")
        g.users = ['vanessa', 'kacey']
        g
      end 
      its(:users) { should == ['vanessa', 'kacey']}
    end
  end

  describe "system_groups" do
    before do
      @u = FactoryGirl.find_or_create(:archivist)
      g = Group.new(:name=>"My Group")
      g.owner_id = @u.id
      g.save!
      
      @system1 = Group.create!(:name=>"System1")
      @system2 = Group.create!(:name=>"System2")
    end
    it "should return groups with nil as the owner" do
      Group.system_groups.should == [@system1, @system2]
    end
  end
end
