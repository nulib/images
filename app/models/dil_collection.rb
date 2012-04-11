class DILCollection < ActiveFedora::Base
  
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  include Dil::RightsMetadata
  

  has_relationship "parts", :is_part_of, :inbound => true
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 
  
  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  has_metadata :name => "descMetadata", :type => Hydra::ModsCollection 

  # Uses the Hydra modsCollection profile for collection list
  has_metadata :name => "members", :type => Hydra::ModsCollectionMembers 


  delegate :title, :to=>'descMetadata', :unique=>true

  validates :title, :presence => true

  def insert_member(pid)
    ds = self.datastreams["members"]   
    node, index = ds.insert_member(pid)
    return node, index
  end
  
end
