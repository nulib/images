require 'spec_helper'

describe User do
  before do
    Group.any_instance.stub :persist_to_ldap
  end
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

  it "should have a user_key" do
    @user = FactoryGirl.find_or_create(:archivist)
    @user.user_key.should == 'archivist1'
    
  end

  it "should have many groups that they own" do
    @user = FactoryGirl.find_or_create(:archivist)
    g1 = Group.new(:name=>'one', :users=>['vanessa'])
    g1.owner = @user
    g1.save!
    g2 = Group.new(:name=>'two', :users=>['vanessa'])
    g2.owner = @user
    g2.save!
    g3 = Group.new(:name=>'three', :users=>['vanessa'])
    g3.owner = FactoryGirl.create(:user)
    g3.save!
    Hydra::LDAP.should_receive(:groups_owned_by_user).with(@user.uid).and_return([g1.code, g2.code])
    @user.owned_groups.should == [g1, g2]
  end

  describe "#groups" do
    before do
      @group = FactoryGirl.build(:user_group)
      @user = FactoryGirl.create(:user)
      @group.users = [@user.uid]
      @group.save
      Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([@group.code])
    end
    it "should return a list" do
      # @user.groups returns the LDAP groups user is a member of and the user's eduPersonAffiliation
      @user.groups.should == [@group].concat(@user.affiliations)
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
      @c1 = FactoryGirl.build(:collection)
      @c1.apply_depositor_metadata(@user.uid)
      @c1.save!
        
      @c2 = FactoryGirl.build(:collection)
      @c2.apply_depositor_metadata(@user.uid)
      @c2.save!

      @c3 = FactoryGirl.create(:collection) #not mine
    end
    it "should return the list" do
      @user.collections.should == [{"id"=>@c1.pid, "title_t"=>[@c1.title]}, {"id"=>@c2.pid, "title_t"=>[@c2.title]}]
    end
  end

end
