class DILCollection < ActiveFedora::Base
  
  include Hydra::ModelMethods
  include Hydra::ModelMixins::RightsMetadata
  
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
      export_xml << "<pid>#{pid}</pid>"
    end
    export_xml << "</collection>"
    return export_xml
  end
  
  def export_image_info_as_xml(email)
    export_xml = "<collection><email>#{email}</email>"
    self.members.find_by_terms(:mods, :relatedItem, :identifier).each do |pid|
      export_xml << "<image><url>#{DIL_CONFIG['dil_fedora_url']}#{pid}#{DIL_CONFIG['dil_fedora_disseminator_ppt']}</url>"
      logger.debug("PID:" << pid)
      image = Multiresimage.find(pid.text)
      export_xml << "<metadata><title>Title: #{image.titleSet_display}</title><agent>Agent: #{image.agentSet_display}</agent><date>Date: #{image.dateSet_display}</date>" << "<description>Description: #{image.descriptionSet_display}</description><subject>Subject: #{image.subjectSet_display}</subject></metadata></image>"  
    end
    export_xml << "</collection>"
    return export_xml
  end
  
end
