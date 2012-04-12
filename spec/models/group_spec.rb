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
end
