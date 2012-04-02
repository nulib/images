class Vrawork  < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  
  has_relationship "parts", :is_part_of, :inbound => true
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 
  
  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  #has_metadata :name => "MODS", :type => ModsArticleDatastream

  # Uses the VRA profile for tracking some of the descriptive metadata
#	has_metadata :name => "VRA", :type => Hydra::VRAWorkDatastream 
   has_metadata :name => "VRA", :type => VRADatastream

  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field 'collection', :string
    m.field 'depositor', :string
  end

  delegate :titleSet_display, :to=>:VRA, :unique=>true
  delegate :agentSet_display, :to=>:VRA, :unique=>true
  delegate :dateSet_display, :to=>:VRA, :unique=>true
  delegate :descriptionSet_display, :to=>:VRA, :unique=>true
  delegate :subjectSet_display, :to=>:VRA, :unique=>true
  delegate :culturalContextSet_display, :to=>:VRA, :unique=>true

  def initialize( attrs={} )
    super
  end 
  
end
