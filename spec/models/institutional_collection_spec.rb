require 'rails_helper'


describe InstitutionalCollection do

  before do
    @collection = InstitutionalCollection.new(pid: "Testing:12335")
    @collection.title="Test Unit|Test Title"
  end

  it "has the correct datastreams" do
    expect(@collection.defaultRights).to be_kind_of(Hydra::Datastream::InheritableRightsMetadata)
    expect(@collection.rightsMetadata).to be_kind_of(Hydra::Datastream::RightsMetadata)
    expect(@collection.descMetadata).to be_kind_of(ActiveFedora::QualifiedDublinCoreDatastream)
  end

  it "has title in the correct datastream" do
    expect(@collection.descMetadata.title) == @collection.title
  end

  describe "to_solr" do
    subject { InstitutionalCollection.new(:title=>"Foobar").to_solr }
    it "should have title_ssim" do
      subject[ActiveFedora::SolrService.solr_name('title', type: :string)].should == "Foobar"
    end
  end

  describe "updating default permissions" do
    it "should create new Institutional Collections as public" do
      subject.default_permissions.should == [{:type=>"group", :access=>"read", :name=>"public"}]
    end
  end



end
