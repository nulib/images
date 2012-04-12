require 'spec_helper'

# member: uid=larry
# member: uid=quentin
# member: uid=theresa
# owner: uid=penelope
describe 'Ldap service' do 
  it "should have users and owners of a group" do
    # If this line isn't true, there was a problem creating (probably already exists.
    Dil::LDAP.create_group('justin1', 'vanessa', ['kacey', 'larry']).should be_true
    Dil::LDAP.users_for_group('justin1').should == ['kacey', 'larry']
    Dil::LDAP.owner_for_group('justin1').should == 'vanessa'
    Dil::LDAP.delete_group('justin1').should be_true
  end
  # describe "#adding_members" do
  #   it "should have users and owners of a group" do
  #     # If this line isn't true, there was a problem creating (probably already exists.
  #     Dil::LDAP.create_group('justin1', 'vanessa', ['kacey', 'larry']).should be_true
  #     Dil::LDAP.users_for_group('justin1').should == ['kacey', 'larry']
  #     Dil::LDAP.owner_for_group('justin1').should == 'vanessa'
  #     Dil::LDAP.delete_group('justin1').should be_true
  #   end
  # end
end
