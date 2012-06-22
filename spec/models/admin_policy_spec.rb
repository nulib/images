require 'spec_helper'

describe AdminPolicy do
  its(:defaultRights) { should be_kind_of Hydra::Datastream::RightsMetadata}
  its(:rightsMetadata) { should be_kind_of Hydra::Datastream::RightsMetadata}
  its(:descMetadata) { should be_kind_of ActiveFedora::QualifiedDublinCoreDatastream}

  describe "when setting attributes" do
    before do
      subject.title = "My title" 
    end
    its(:title) { should == "My title"}
  end
    


end
