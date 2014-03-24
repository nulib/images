class Vrawork  < ActiveFedora::Base
  include Hydra::ModelMethods
  #include ActiveFedora::Relationships
  include Hydra::ModelMixins::RightsMetadata
  
  #has_relationship "parts", :is_part_of, :inbound => true
  has_and_belongs_to_many :multiresimages, :class => "Multiresimage", :property=> :has_image
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 
  
  # Uses the VRA profile for tracking the descriptive metadata
   has_metadata :name => "VRA", :type => VRADatastream


  # A place to put extra metadata values
  has_metadata :name => "properties", :type => Hydra::Datastream::Properties

  # External datastream
  has_metadata :name => "POLICY", :type => ActiveFedora::Datastream, :controlGroup=>'E'

  delegate :titleSet_display_work, :to=>:VRA, :unique=>true
  delegate :agentSet_display_work, :to=>:VRA, :unique=>true
  delegate :dateSet_display_work, :to=>:VRA, :unique=>true
  delegate :descriptionSet_display_work, :to=>:VRA, :unique=>true
  delegate :subjectSet_display_work, :to=>:VRA, :unique=>true
  delegate :culturalContextSet_display_work, :to=>:VRA, :unique=>true
  delegate :relationSet_display_work, :to=>:VRA, :unique=>true
  #delegate :ref_id, :to=>:VRA, :unique=>true

  # The xml_template uses the vra:image tags when creating the vra work
  #
  def update_vra_work_tag
    vra_xml = self.datastreams["VRA"].ng_xml.to_s.gsub("<vra:image","<vra:work")
    vra_xml = vra_xml.gsub!("</vra:image>","</vra:work>")
    self.datastreams["VRA"].content = vra_xml
  end
  
  def update_ref_id(ref_id)
    #Refactor to use proxy/delegates
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:work[@refid]')
    node_set[0].set_attribute("refid", ref_id)
    self.datastreams["VRA"].content = self.datastreams["VRA"].ng_xml.to_s
    #Need to let Hydra know ds has been updated
    #self.datastreams["VRA"].dirty = true
  end
  
  def update_relation_set(image_pid)
    #Refactor to use proxy/delegates
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:work/vra:relationSet/vra:relation')
    node_set[0].set_attribute("pref", "true")
    node_set[0].set_attribute("relids", image_pid)
    node_set[0].set_attribute("type", "imageIs")
    self.datastreams["VRA"].content = self.datastreams["VRA"].ng_xml.to_s
    #Need to let Hydra know ds has been updated
    #self.datastreams["VRA"].dirty = true
  end
  
   #def update_agent_set(agent_set_display)
    #self.agentSet_display_work = agent_set_display
   
    #node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:work/vra:agentSet/vra:display')  
    #logger.debug("NODESET TEST: " + node_set.to_xml)
    #self.datastreams["VRA"].agentSet_display = node_set[0].content
    #Not sure why this doesn't work
    #self.datastreams["VRA"].agentSet_display = agent_set_display
  # end
end
