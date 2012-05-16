class Vrawork  < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  
  has_relationship "parts", :is_part_of, :inbound => true
  has_and_belongs_to_many :multiresimages, :class => "Multiresimage", :property=> :has_image
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 
  
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
  #delegate :ref_id, :to=>:VRA, :unique=>true

  #def initialize( attrs={} )
   # super
  #end
  
  # The xml_template uses the vra:image tags when creating the vra work
  #
  def update_vra_work_tag
    vra_xml = self.datastreams["VRA"].content.gsub("<vra:image","<vra:work")
    vra_xml = vra_xml.gsub!("</vra:image>","</vra:work>")
    self.datastreams["VRA"].content = vra_xml
    #self.save!
  end
  
  def update_ref_id(ref_id)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:work[@refid]')
    node_set[0].set_attribute("refid", ref_id)
    #self.save!
  end
  
  def update_relation_set(image_pid)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:work/vra:relationSet/vra:relation')
    node_set[0].set_attribute("pref", "true")
    node_set[0].set_attribute("relids", image_pid)
    node_set[0].set_attribute("type", "imageIs")
	#self.save!
  end
  
   def update_agent_set(agent_set_display)
     self.agentSet_display = agent_set_display 
   end
  
end
