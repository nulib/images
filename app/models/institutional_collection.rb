#require 'json'
#require 'dil/pid_minter'

class InstitutionalCollection < ActiveFedora::Base
  
  include Hydra::ModelMethods
  include Hydra::ModelMixins::RightsMetadata
  #include Hydra::ModelMixins::InheritableRightsMetadata
  #include DIL::PidMinter
  
  has_many :multiresimages, :class_name=> "Multiresimage", :property=> :has_image
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "defaultRights", :type => Hydra::Datastream::InheritableRightsMetadata 
  
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

 # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  #has_metadata :name => "descMetadata", :type => Hydra::ModsCollection 

  #delegate :title, :to=>'descMetadata', :unique=>true

  #delegate :owner, :to => 'members', :unique => true

  #validates :title, :presence => true

 
  def to_solr(solr_doc=Hash.new)
    solr_doc = super(solr_doc)
    
    #parent_collection_hash = Hash["is_top_level_collection_ssim" => value]
    
    #solr_doc = solr_doc.merge(parent_collection_hash)
    #solr_doc = solr_doc.merge({"object_type_facet" => 'Collection'})
    #solr_doc = solr_doc.merge({"title_ssim" => self.title})
    #solr_doc = solr_doc.merge({"title_tesim" => self.title})
    #solr_doc
  end

 
end