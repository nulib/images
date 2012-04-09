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
      @collection.rightsMetadata.update_permissions("group"=>{@group.code.to_s=>'read'}) 
      @collection.save!
      
      @image = Multiresimage.new()
      @image.collection=@collection
      @image.save

    end
    it "should be able to view the image" do
      subject.can?(:read, @image).should be_true
    end
  end
end

