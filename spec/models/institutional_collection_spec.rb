require 'rails_helper'




describe InstitutionalCollection do

  before do
    @public_collection = InstitutionalCollection.new(pid: "Testing:12335")
    @public_collection.save
    @public_collection.title="Test Unit|Test Title"
    @public_collection.rightsMetadata
    @public_collection.default_permissions
    @public_collection.default_permissions=[{:type=>"group", :access=>"read", :name=>"public"}]#likely this would be done in model when created
    @public_collection.save
  end
  after { @public_collection.delete }

  it "has the correct datastreams" do
    expect(@public_collection.defaultRights).to be_kind_of(Hydra::Datastream::InheritableRightsMetadata)
    expect(@public_collection.rightsMetadata).to be_kind_of(Hydra::Datastream::RightsMetadata)
    expect(@public_collection.descMetadata).to be_kind_of(ActiveFedora::QualifiedDublinCoreDatastream)
  end

  it "has the title attribute in the descMetadata datastream" do
    expect(@public_collection.descMetadata.title) == @public_collection.title
  end

  describe "to_solr" do
    subject { @public_collection.to_solr }
    it "should have title_tesim" do
      subject[ActiveFedora::SolrService.solr_name('title', type: :string)].should == @public_collection.title
    end
    it "should have inheritable_read_access_ssim" do
      subject[ActiveFedora::SolrService.solr_name('inheritable_read_access_group', type: :symbol)].should == ["public"]
    end
  end

  describe "Setting (inheritable) default_permissions" do
    it "New Institutional Collections should be public by default" do
      subject.default_permissions.should == [{:type=>"group", :access=>"read", :name=>"public"}]
    end
  end

  describe "Attribute validations" do
    #if that's what we decide ultimately
    it "Valid title must contain a Unit and Title concatanated with a pipe (|)" do
      coll = InstitutionalCollection.new
      coll.title = "oneword"
      coll.valid?.should be false
    end
  end


  #
 # Policy-based Access Controls
 #
 describe "When accessing assets with Institutional Collection associated" do

   subject { Ability.new(nil) } #non-logged in user
    context "Given a Collection grants access to public" do
      before do
        @policy = InstitutionalCollection.new(pid: "testing:88888")
        @policy.title="Unit|Title"
        @policy.save
        @policy.rightsMetadata
        @policy.default_permissions
        @policy.default_permissions= [{:type=>"group", :access=>"read", :name=>"public"}]
        @policy.save
      end
      after { @policy.delete }
    	context "And a subscribing multiresimage does not grant access" do
        #need to look at what our images grant by default
    	  before do
          @asset = Multiresimage.new()
          @asset.add_relationship(:is_governed_by, @policy)
          @asset.save
        end
        after { @asset.delete }
    		it "Then I should be able to view the asset when not logged in" do
    		  subject.can?(:read, @asset).should be true
  		  end
      end
    end

    context "Given a Collection that does not grant access to the public" do
      before do
        @policy = InstitutionalCollection.new(pid: "testing:9999")
        @policy.title="Unit|Title"
        @policy.save
        @policy.rightsMetadata
        @policy.default_permissions
        @policy.default_permissions= [{:type=>"group", :access=>"read", :name=>"registered"}]
        @policy.save
      end
      after { @policy.delete }
    	context "And a subscribing multiresimage does not grant access" do
        #need to look at what our images grant by default
    	  before do
          @asset = Multiresimage.new()
          @asset.add_relationship(:is_governed_by, @policy)
          @asset.save
        end
        after { @asset.delete }
    		it "Then I should not be able to view the asset when not logged in" do
    		  subject.can?(:read, @asset).should be false
  		  end
      end
    end
  end






end
