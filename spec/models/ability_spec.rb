require 'spec_helper'

describe "a user" do
  before do
    @user = FactoryGirl.create(:user)
  end
  subject { Ability.new(@user) }
  context "who is a member of a group associated with an image" do
    before do
      @group = FactoryGirl.build(:user_group)
      @group.users = [@user.email]
      @group.save!

      @collection = DILCollection.new()
      
      @image = Multiresimage.new()
      @image.collection=@collection
      @image.save
    end
    context "and the group has read permissions" do
      before do
        @collection.rightsMetadata.update_permissions("group"=>{@group.code.to_s=>'read'}) 
        @collection.save!
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
    context "and the group has edit permissions" do
      before do
        @collection.rightsMetadata.update_permissions("group"=>{@group.code.to_s=>'edit'}) 
        @collection.save!
      end
      it "should be able to view the image" do
        subject.can?(:read, @image).should be_true
      end
      it "should be able to destroy the image" do
        subject.can?(:destroy, @image).should be_true
      end
      it "should be able to edit the image" do
        subject.can?(:destroy, @image).should be_true
      end
    end
  end
end

