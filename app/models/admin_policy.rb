class AdminPolicy < ActiveFedora::Base

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "defaultRights", :type => Hydra::Datastream::RightsMetadata 

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_metadata :name =>'descMetadata', :type => ActiveFedora::QualifiedDublinCoreDatastream

  delegate :title, :to=>'descMetadata', :unique=>true

end
