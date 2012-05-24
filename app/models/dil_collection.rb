class DILCollection < ActiveFedora::Base
  
  include Hydra::ModelMethods
  include Dil::RightsMetadata
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  has_metadata :name => "descMetadata", :type => Hydra::ModsCollection 

  # Uses the Hydra modsCollection profile for collection list
  has_metadata :name => "members", :type => Hydra::ModsCollectionMembers 


  delegate :title, :to=>'descMetadata', :unique=>true

  validates :title, :presence => true

  def insert_member(image)
    image.collections << self
    image.save!
    members.insert_member(:member_id=>image.pid, :member_title=>image.titleSet_display)
  end
  
  def export_pids_as_xml
    export_xml = "<collection>"
    self.members.find_by_terms(:mods, :relatedItem, :identifier).each do |pid|
      export_xml << "<pid>" << pid << "</pid>"
    end
    export_xml << "</collection>"
    return export_xml
  end
  
  def export_image_urls_as_xml
    url = "/inu:sdef-image/getWithLongSide?length=100"
    #export_xml = "<collection>"
    export_xml = ""
    self.members.find_by_terms(:mods, :relatedItem, :identifier).each do |pid|
      #export_xml << "<imageLink>" << "http://cecil.library.northwestern.edu:8983/fedora/get/" << pid << "/inu:sdef-image/getWithLongSide?length=100</imageLink>"
      export_xml << "http://cecil.library.northwestern.edu:8983/fedora/get/" << pid << "/inu:sdef-image/getWithLongSide?length=500|"
    end
    #export_xml << "</collection>"
    return export_xml
  end
  
end
