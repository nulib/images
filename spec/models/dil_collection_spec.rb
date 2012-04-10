require 'spec_helper'

describe DILCollection do
  describe "a new instance" do
    subject { DILCollection.new }
    it "should have a title" do
      subject.title = 'foo'
      subject.title.should == 'foo'
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
  end
end
  

