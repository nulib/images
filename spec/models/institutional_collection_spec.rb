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


  #
 # Policy-based Access Controls
 #
 describe "When accessing assets with Institutional Collection associated" do
   before do
    #  @user = FactoryGirl.build(:martia_morocco)
    #  RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
   end
  #  before(:all) do
  #    class TestAbility
  #      include Hydra::PolicyAwareAbility
  #    end
  # end

   subject { Ability.new(nil) }
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
