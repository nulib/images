require 'spec_helper'

describe "When I am searching for content" do
  context "Given a Faculty-created image with no custom access set" do
    before do
      @image = Multiresimage.find("inu:dil-default-access-image")
    end
    context "Then someone with NU id" do
      before do
        @user = FactoryGirl.find_or_create(:nu_id_holder)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should not be able to discover the image" do
        subject.can?(:discover, @image).should be_false
      end
    end
    context "Then the Creator" do
      before do
        @user = FactoryGirl.find_or_create(:joe_creator)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should be able to discover the image" do
        subject.can?(:discover, @image).should be_true
      end
    end
    context "Then a Repository Admin" do
      before do
        @user = FactoryGirl.find_or_create(:alice_admin)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should be able to discover the image" do
        subject.can?(:discover, @image).should be_true
      end
    end
  end

  context "Given a Faculty-created image which NU has read access to" do
    before do
      @image = Multiresimage.find("inu:dil-nu-read-access-image")
    end
    context "The someone with NU id" do
      before do
        @user = FactoryGirl.find_or_create(:nu_id_holder)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should be able to discover the image" do
        subject.can?(:discover, @image).should be_true
      end
    end
  end

  context "Given a Faculty-created image with collaborator" do
    before do
      @image = Multiresimage.find("inu:dil-nu-read-access-image")
    end
    context "Then a collaborator with edit access" do
      before do
        @user = FactoryGirl.find_or_create(:calvin_collaborator)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should be able to discover the image" do
        subject.can?(:discover, @image).should be_true
      end
    end
  end
  
  context "Given a Faculty-created object where dept can read & NU can discover" do
    before do
      @image = Multiresimage.find("inu:dil-dept-access-image")
    end
    context "Then someone with NU id" do
      before do
        @user = FactoryGirl.find_or_create(:nu_id_holder)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should be able to discover the image" do
        subject.can?(:discover, @image).should be_true
      end
    end
    context "Then someone whose department has read access" do
      before do
        @user = FactoryGirl.find_or_create(:martia_morocco)
        Group.any_instance.stub :persist_to_ldap
      end
      subject { Ability.new(@user) }
      it "should be able to discover the image" do
        subject.can?(:discover, @image).should be_true
      end
    end
  end


  context "Given a policy grants edit access to a group I belong to" do
    before do
      # @image = Multiresimage.new()
      # @image.policy=@policy
      # @image.save
    end
    it "Then I should be able to discover the image" do
      pendin
      subject.can?(:discover, @image).should be_true
    end
  end
  context "Given a policy grants read access to a group I belong to" do
    before do
      # @image = Multiresimage.new()
      # @image.policy=@policy
      # @image.save
    end
    it "Then I should be able to discover the image" do
      pending
      subject.can?(:discover, @image).should be_true
    end
  end
end

