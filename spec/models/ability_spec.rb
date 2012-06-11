require 'spec_helper'

describe "a user" do
  before do
    @user = FactoryGirl.create(:user)
    Group.any_instance.stub :persist_to_ldap
  end
  subject { Ability.new(@user) }
  context "who is a member of a group" do
    before do
        @group = FactoryGirl.build(:user_group)
        @group.users = [@user.email]
        @group.save!
        Dil::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([@group.code])
        @user.stub(:groups=>[@group])
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

      context "that has an image" do
        before do
          @image = Multiresimage.new()
          @image.collections=[@collection]
          @image.save
        end

        it "should be able to view the image" do
          subject.can?(:read, @image).should be_true
        end
        it "should be able to destroy the image" do
          subject.can?(:destroy, @image).should be_true
        end
        it "should be able to edit the image" do
          subject.can?(:edit, @image).should be_true
        end
        it "should be able to update the image" do
          subject.can?(:update, @image).should be_true
        end
      end
    end
    context "that has read permission on a collection" do
      before do
        @collection = FactoryGirl.build(:collection)
        @collection.rightsMetadata.update_permissions("group"=>{@group.code.to_s=>'read'}) 
        @collection.save!
      end
      context "that has an image" do
        before do
          @image = Multiresimage.new()
          @image.collections=[@collection]
          @image.save
        end

        it "should be able to view the image" do
          subject.can?(:read, @image).should be_true
        end
        it "should not be able to destroy the image" do
          subject.can?(:destroy, @image).should_not be_true
        end
        it "should not be able to edit the image" do
          subject.can?(:destroy, @image).should_not be_true
        end
      end
    end
  end
  context "who is an owner of a group" do
    before do
        @group = FactoryGirl.build(:user_group, :owner=>@user)
        Dil::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
        @group.users = [FactoryGirl.build(:user).uid]
        @group.save!
        @user.stub(:groups=>[@group])
    end
    it "should be able to edit it" do
      subject.can?(:edit, @group).should be_true
    end
  end
  it "should be able to create DILCollections" do
    Dil::LDAP.should_receive(:groups_for_user).with(@user.uid).and_return([])
    subject.can?(:create, DILCollection).should be_true
  end
end

