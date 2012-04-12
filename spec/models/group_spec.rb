require 'spec_helper'

describe Group do
  before  do
    Group.any_instance.stub :persist_to_ldap
  end
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
      it "should store the group in ldap" do
        subject.assign_code
        subject.save.should be_true
      end
    end
  end

  describe "system_groups" do
    before do
      @u = FactoryGirl.find_or_create(:archivist)
      @g = Group.create!(:name=>"My Group", :owner_id => @u.id, :users=>["vanessa"])
      @system1 = Group.create!(:name=>"System1", :code=>'faculty', :users=>['kacey'])
      @system2 = Group.create!(:name=>"System2", :code=>'students', :users=>['kacey'])
    end
    after do
      @g.delete
      @system1.delete
      @system2.delete
    end
    it "should return groups with nil as the owner" do
      Group.system_groups.should == [@system1, @system2]
    end
  end

end
