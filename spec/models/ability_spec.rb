require 'spec_helper'

describe "given a Faculty-created image with no custom access set" do
  before do
    @image = Multiresimage.find("inu:dil-default-access-image")
  end
  context "someone with NU id" do
    before do
      @user = FactoryGirl.find_or_create(:nu_id_holder)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should not be able to discover the image" do
      subject.can?(:discover, @image).should be_false
    end
    it "should not be able to view the image" do
      subject.can?(:read, @image).should be_false
    end
    it "should not be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_false
      subject.can?(:update, @image).should be_false
      subject.can?(:destroy, @image).should be_false
    end
  end
  context "the Creator" do
    before do
      @user = FactoryGirl.find_or_create(:joe_creator)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should be able to discover the image" do
      subject.can?(:discover, @image).should be_true
    end
    it "should be able to view the image" do
      subject.can?(:read, @image).should be_true
    end
    it "should be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_true
      subject.can?(:update, @image).should be_true
      subject.can?(:destroy, @image).should be_true
    end
    it "should not be able to see the admin view of the image" do
      subject.can?(:admin, @image).should be_false
    end
  end
  context "a Repository Admin" do
    before do
      @user = FactoryGirl.find_or_create(:alice_admin)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should be able to discover the image" do
      subject.can?(:discover, @image).should be_true
    end
    it "should be able to view the image" do
      subject.can?(:read, @image).should be_true
    end
    it "should be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_true
      subject.can?(:update, @image).should be_true
      subject.can?(:destroy, @image).should be_true
    end
    it "should not be able to see the admin view of the image" do
      subject.can?(:admin, @image).should be_true
    end
  end
end

describe "given a Faculty-created image which NU has read access to" do
  before do
    @image = Multiresimage.find("inu:dil-nu-read-access-image")
  end
  context "someone with NU id" do
    before do
      @user = FactoryGirl.find_or_create(:nu_id_holder)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should be able to discover the image" do
      subject.can?(:discover, @image).should be_true
    end
    it "should be able to view the image" do
      subject.can?(:read, @image).should be_true
    end
    it "should not be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_false
      subject.can?(:update, @image).should be_false
      subject.can?(:destroy, @image).should be_false
    end
    it "should not be able to see the admin view of the image" do
      subject.can?(:admin, @image).should be_false
    end
  end
end

describe "given a Faculty-created image with collaborator" do
  before do
    @image = Multiresimage.find("inu:dil-nu-read-access-image")
  end
  context "a collaborator with edit access" do
    before do
      @user = FactoryGirl.find_or_create(:calvin_collaborator)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should be able to discover the image" do
      subject.can?(:discover, @image).should be_true
    end
    it "should be able to view the image" do
      subject.can?(:read, @image).should be_true
    end
    it "should be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_true
      subject.can?(:update, @image).should be_true
      subject.can?(:destroy, @image).should be_true
    end
    it "should not be able to see the admin view of the image" do
      subject.can?(:admin, @image).should be_false
    end
  end
end

describe "given a Faculty-created object where dept can read & NU can discover" do
  before do
    @image = Multiresimage.find("inu:dil-dept-access-image")
  end
  context "someone with NU id" do
    before do
      @user = FactoryGirl.find_or_create(:nu_id_holder)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should be able to discover the image" do
      subject.can?(:discover, @image).should be_true
    end
    it "should not be able to view the image" do
      subject.can?(:read, @image).should be_false
    end
    it "should not be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_false
      subject.can?(:update, @image).should be_false
      subject.can?(:destroy, @image).should be_false
    end
    it "should not be able to see the admin view of the image" do
      subject.can?(:admin, @image).should be_false
    end
  end
  context "someone whose department has read access" do
    before do
      @user = FactoryGirl.find_or_create(:martia_morocco)
      Group.any_instance.stub :persist_to_ldap
    end
    subject { Ability.new(@user) }
    it "should be able to discover the image" do
      subject.can?(:discover, @image).should be_true
    end
    it "should be able to view the image" do
      subject.can?(:read, @image).should be_true
    end
    it "should not be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_false
      subject.can?(:update, @image).should be_false
      subject.can?(:destroy, @image).should be_false
    end
    it "should not be able to see the admin view of the image" do
      subject.can?(:admin, @image).should be_false
    end
  end
end

describe "a user" do
  before do
    @user = FactoryGirl.create(:staff)
    Group.any_instance.stub :persist_to_ldap
  end
  subject { Ability.new(@user) }
  describe "user_groups" do
    it "should have affilliation groups" do
      subject.user_groups(@user, nil).should == ['public', 'staff', 'registered']
    end
  end

  it "should be able to create admin policies" do
    subject.can?(:create, AdminPolicy).should be_true
  end
  context "who is a member of a group" do
    before do
        @group = FactoryGirl.build(:user_group)
        @group.users = [@user.email]
        @group.save!
        Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([@group.code])
        #@user.stub(:groups=>[@group])
    end
    
    context "that has edit permission on a collection" do
      before do
        @collection = FactoryGirl.build(:collection)
        @collection.rightsMetadata.update_permissions("group"=>{@group.code.to_s=>'edit'}) 
        @collection.save!
      end
      it "should be able to edit the collection" do
        subject.can?(:edit, @collection).should be_true
      end
      it "should be able to update the collection" do
        subject.can?(:update, @collection).should be_true
      end
    end
    context "that has read permission on a collection" do
      before do
        @collection = FactoryGirl.build(:collection)
        @collection.rightsMetadata.update_permissions("group"=>{@group.code.to_s=>'read'}) 
        @collection.save!
      end
    end
  end

  context "who is an owner of a group" do
    before do
        @group = FactoryGirl.build(:user_group, :owner=>@user)
        Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
        @group.users = [FactoryGirl.build(:user).uid]
        @group.save!
        #@user.stub(:groups=>[@group])
    end
    it "should be able to edit it" do
      subject.can?(:edit, @group).should be_true
    end
  end
  it "should be able to create DILCollections" do
    Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
    subject.can?(:create, DILCollection).should be_true
  end

end

describe "Policy-enforcement: accessing an object whose" do
  context "policy grants edit access to a group I belong to" do
    before do
      # @image = Multiresimage.new()
      # @image.policy=@policy
      # @image.save
    end
    it "should be able to view the image" do
      pending
      subject.can?(:read, @image).should be_true
    end
    it "should be able to destroy the image" do
      pending
      subject.can?(:destroy, @image).should be_true
    end
    it "should be able to edit the image" do
      pending
      subject.can?(:edit, @image).should be_true
    end
    it "should be able to update the image" do
      pending
      subject.can?(:update, @image).should be_true
    end
  end
  context "policy grants read access to a group I belong to" do
    before do
      # @image = Multiresimage.new()
      # @image.policy=@policy
      # @image.save
    end
    it "should be able to view the image" do
      pending
      subject.can?(:read, @image).should be_true
    end
    it "should be able to destroy the image" do
      pending
      subject.can?(:destroy, @image).should be_false
    end
    it "should be able to edit the image" do
      pending
      subject.can?(:edit, @image).should be_false
    end
    it "should be able to update the image" do
      pending
      subject.can?(:update, @image).should be_false
    end
  end
end
