require 'spec_helper'

describe DILCollection do
  describe "a new instance" do
    subject { DILCollection.new }
    it "should have a title" do
      subject.title = 'foo'
      subject.title.should == 'foo'
    end
    it "should require a title" do
      subject.save.should be_false
      subject.errors[:title].should == ["can't be blank"]
    end
  end
  describe "a saved instance" do
    before do
      @user = FactoryGirl.find_or_create(:archivist)
      @c =  DILCollection.new(:title=>"My title")
		  @c.apply_depositor_metadata(@user.uid)
      @c.save!
    end
    subject { @c.to_solr }
    context "converted to solr" do
      it "should have a depositor" do
        subject["rightsMetadata_edit_access_machine_person_t"].should == ['archivist1']
      end
      it "should have a title" do
        subject["title_t"].should == ['My title']
      end
    end

    context "adding a member image" do
      before do
        @img = Multiresimage.create
        @c.insert_member(@img)
      end
      it "should set the collection_id on the image" do
        @img.collection.should == @c
      end
    end
  end
  context "with rightsMetadata" do
    subject do
      m = DILCollection.new(:title=>"My title")
      m.rightsMetadata.update_permissions("person"=>{"person1"=>"read","person2"=>"discover"}, "group"=>{'group-6' => 'read', "group-7"=>'read', 'group-8'=>'edit'})
      m.save
      m
    end
    it "should have read groups accessor" do
      subject.read_groups.should == ['group-6', 'group-7']
    end
    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
  end
end
  

