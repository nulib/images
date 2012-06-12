require 'spec_helper'

describe User do
  before do
    Group.any_instance.stub :persist_to_ldap
    @user = FactoryGirl.find_or_create(:archivist)
    @g1 = FactoryGirl.create(:user_group, :users=>[@user.uid], :owner=>FactoryGirl.create(:user))
    Hydra::LDAP.stub(:groups_for_user).with(@user.uid).and_return([@g1.code])
  end
  subject {::RoleMapper.roles(@user.uid)}
  it { should == [@g1.code]}
end
