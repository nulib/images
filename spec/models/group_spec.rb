require 'spec_helper'

describe Group do
  describe "a new instance " do
    subject { Group.new }
    it "should require a name" do
      subject.save.should be_false
      subject.errors[:name].should == ["can't be blank"]
    end
  end

  describe "a valid instance" do 
    subject { FactoryGirl.build(:user_group) }
    its(:owner) { should be_kind_of User} 
    its(:name) { should == "Factory Group"} 

    context "with users" do
      before do
        subject.users = ['vanessa', 'kacey']
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
      
      @system1 = Group.create!(:name=>"System1", :code=>'faculty')
      @system2 = Group.create!(:name=>"System2", :code=>'students')
    end
    it "should return groups with nil as the owner" do
      Group.system_groups.should == [@system1, @system2]
    end
  end
end
