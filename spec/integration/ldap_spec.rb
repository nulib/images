require 'spec_helper'

# member: uid=larry
# member: uid=quentin
# member: uid=theresa
# owner: uid=penelope
describe 'Ldap service' do 
  before do
    # If this line isn't true, there was a problem creating (probably already exists.
    Dil::LDAP.create_group('justin1', 'vanessa', ['kacey', 'larry']).should be_true
  end
  after do
    Dil::LDAP.delete_group('justin1').should be_true
  end
  it "should have users and owners of a group" do
    Dil::LDAP.users_for_group('justin1').should == ['kacey', 'larry']
    Dil::LDAP.owner_for_group('justin1').should == 'vanessa'
  end

  describe "#groups_owned_by_user" do
    before do
      Dil::LDAP.create_group('justin2', 'vanessa', ['kacey', 'larry']).should be_true
      Dil::LDAP.create_group('justin3', 'theresa', ['kacey', 'larry']).should be_true
    end
    after do
      Dil::LDAP.delete_group('justin2').should be_true
      Dil::LDAP.delete_group('justin3').should be_true
    end
    it "should return the list" do
      Dil::LDAP.groups_owned_by_user('vanessa').should == ['justin1', 'justin2']
    end
  end
  describe "#adding_members" do
    it "should have users and owners of a group" do
      Dil::LDAP.add_users_to_group('justin1', ['theresa', 'penelope']).should be_true
      Dil::LDAP.users_for_group('justin1').should == ['kacey', 'larry', 'theresa', 'penelope']
    end
  end
end
