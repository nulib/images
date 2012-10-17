require 'spec_helper'

# NOTES: 
#   See spec/requests/... for test coverage describing WHAT should appear on a page based on access permissions
#   Test coverage for discover permission is in spec/requests/gated_discovery_spec.rb


describe "Given a Faculty-created image with no custom access set" do
  before do
    @image = Multiresimage.find("inu:dil-default-access-image")
  end
  context "Then someone with NU id" do
    before do
      @user = FactoryGirl.find_or_create(:nu_id_holder)
      stub_groups_for_user @user
    end
    subject { Ability.new(@user) }
    it "should not be able to view the image" do
      subject.can?(:read, @image).should be_false
    end
    it "should not be able to edit, update and destroy the image" do
      subject.can?(:edit, @image).should be_false
      subject.can?(:update, @image).should be_false
      subject.can?(:destroy, @image).should be_false
    end
  end
  context "Then the Creator" do
    before do
      @user = FactoryGirl.find_or_create(:joe_creator)
      stub_groups_for_user @user
    end
    subject { Ability.new(@user) }

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
  context "Then a Repository Admin" do
    before do
      @user = FactoryGirl.find_or_create(:alice_admin)
      stub_groups_for_user(@user)
    end
    subject { Ability.new(@user) }

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

describe "Given a Faculty-created image which NU has read access to" do
  before do
    @image = Multiresimage.find("inu:dil-nu-read-access-image")
  end
  context "The someone with NU id" do
    before do
      @user = FactoryGirl.find_or_create(:nu_id_holder)
      stub_groups_for_user @user
    end
    subject { Ability.new(@user) }

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

describe "Given a Faculty-created image with collaborator" do
  before do
    @image = Multiresimage.find("inu:dil-nu-read-access-image")
  end
  context "Then a collaborator with edit access" do
    before do
      @user = FactoryGirl.find_or_create(:calvin_collaborator)
      stub_groups_for_user @user
    end
    subject { Ability.new(@user) }

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

describe "Given a Faculty-created object where dept can read & NU can discover" do
  before do
    @image = Multiresimage.find("inu:dil-dept-access-image")
  end
  context "Then someone with NU id" do
    before do
      @user = FactoryGirl.find_or_create(:nu_id_holder)
      stub_groups_for_user @user
    end
    subject { Ability.new(@user) }

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
  context "Then someone whose department has read access" do
    before do
      @user = FactoryGirl.find_or_create(:martia_morocco)
      stub_groups_for_user(@user)
    end
    subject { Ability.new(@user) }

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
    stub_groups_for_user(@user)
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
        @group.stub :persist_to_ldap
        @group.save!
        Hydra::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([@group.code])
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

#
# Policy-based Access Controls
#
describe "When accessing images with Policies associated" do
  before do
    @user = FactoryGirl.find_or_create(:martia_morocco)
    stub_groups_for_user(@user)
  end
  subject { Ability.new(@user) }
  context "Given a policy grants read access to a group I belong to" do
    before do
      @policy = AdminPolicy.new
      @policy.default_permissions = [{:type=>"group", :access=>"read", :name=>"africana-faculty"}]
      @policy.save
    end
    after { @policy.delete }
  	context "And a subscribing image does not grant access" do
  	  before do
        @image = Multiresimage.new()
        @image.admin_policy = @policy
        @image.save
      end
      after { @image.delete }
  		it "Then I should be able to view the image" do
  		  subject.can?(:read, @image).should be_true
		  end
      it "Then I should not be able to edit, update and destroy the image" do
        subject.can?(:edit, @image).should be_false
        subject.can?(:update, @image).should be_false
        subject.can?(:destroy, @image).should be_false
      end
    end
  end
  context "Given a policy grants edit access to a group I belong to" do
    before do
      @policy = AdminPolicy.new
      @policy.default_permissions = [{:type=>"group", :access=>"edit", :name=>"africana-faculty"}]
      @policy.save
    end
    after { @policy.delete }
  	context "And a subscribing image does not grant access" do
  	  before do
        @image = Multiresimage.new()
        @image.admin_policy = @policy
        @image.save
      end
      after { @image.delete }
  		it "Then I should be able to view the image" do
  		  subject.can?(:read, @image).should be_true
		  end
  		it "Then I should be able to edit/update/destroy the image" do
        subject.can?(:edit, @image).should be_true
        subject.can?(:update, @image).should be_true
        subject.can?(:destroy, @image).should be_true
      end
		end
  	context "And a subscribing image grants read access to me as an individual" do
  	  before do
        @image = Multiresimage.new()
        @image.read_users = [@user.uid]
        @image.admin_policy = @policy
        @image.save
      end
      after { @image.delete }
  		it "Then I should be able to view the image" do
  		  subject.can?(:read, @image).should be_true
		  end
      it "Then I should be able to edit/update/destroy the image" do
        subject.can?(:edit, @image).should be_true
        subject.can?(:update, @image).should be_true
        subject.can?(:destroy, @image).should be_true
      end
    end
  end

  context "Given a policy does not grant access to any group I belong to" do
    before do
      @policy = AdminPolicy.new
      @policy.save
    end
    after { @policy.delete }
    context "And a subscribing image does not grant access" do
      before do
        @image = Multiresimage.new()
        @image.admin_policy = @policy
        @image.save
      end
      after { @image.delete }
		  it "Then I should not be able to view the image" do
  		  subject.can?(:read, @image).should be_false
		  end
      it "Then I should not be able to edit/update/destroy the image" do
        subject.can?(:edit, @image).should be_false
        subject.can?(:update, @image).should be_false
        subject.can?(:destroy, @image).should be_false
      end
    end
    context "And a subscribing image grants read access to me as an individual" do
      before do
        @image = Multiresimage.new()
        @image.read_users = [@user.uid]
        @image.admin_policy = @policy
        @image.save
      end
      after { @image.delete }
		  it "Then I should be able to view the image" do
  		  subject.can?(:read, @image).should be_true
		  end
      it "Then I should not be able to edit/update/destroy the image" do
        subject.can?(:edit, @image).should be_false
        subject.can?(:update, @image).should be_false
        subject.can?(:destroy, @image).should be_false
      end
    end
  end
end
