require 'spec_helper'

describe 'Ldap service' do 
  before do
    # If this line isn't true, there was a problem creating (probably already exists.
    Dil::LDAP.create_group('justin1', 'Test Group', 'quentin', ['kacey', 'larry', 'ursula']).should be_true
  end
  after do
    Dil::LDAP.delete_group('justin1').should be_true
  end
  it "should have description, users, owners of a group" do
    Dil::LDAP.title_of_group('justin1').should == 'Test Group'
    Dil::LDAP.users_for_group('justin1').should == ['kacey', 'larry', 'ursula']
    Dil::LDAP.owner_for_group('justin1').should == 'quentin'
  end

  describe "#groups_owned_by_user" do
    before do
      Dil::LDAP.create_group('justin2', 'Test Group', 'quentin', ['kacey', 'larry']).should be_true
      Dil::LDAP.create_group('justin3', 'Test Group', 'theresa', ['kacey', 'larry']).should be_true
    end
    after do
      Dil::LDAP.delete_group('justin2').should be_true
      Dil::LDAP.delete_group('justin3').should be_true
    end
    it "should return the list" do
      Dil::LDAP.groups_owned_by_user('quentin').should == ['justin1', 'justin2']
    end
  end
  describe "#adding_members" do
    it "should have users and owners of a group" do
      Dil::LDAP.add_users_to_group('justin1', ['theresa', 'penelope']).should be_true
      Dil::LDAP.users_for_group('justin1').should == ['kacey', 'larry', 'ursula', 'theresa', 'penelope']
    end
  end
  describe "#removing_members" do
    it "should remove users from the group" do
      Dil::LDAP.remove_users_from_group('justin1', ['kacey', 'larry']).should be_true
      Dil::LDAP.users_for_group('justin1').should == ['ursula']
    end
  end
end
