class Vrawork  < ActiveFedora::Base
  include Hydra::ModelMethods
  #include ActiveFedora::Relationships
  include Hydra::ModelMixins::RightsMetadata

  after_create :update_vra_work_tag

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


  # The xml_template uses the vra:image tags when creating the vra work
  def update_vra_work_tag
    image_pid = self.datastreams[ "VRA" ].ng_xml.xpath( '/vra:vra/vra:image' )[ 0 ][ 'refid' ]

    # Change the work reference to an image reference
    vra_xml = self.datastreams["VRA"].ng_xml.to_s.sub("<vra:work","<vra:image")
    vra_xml = vra_xml.sub("</vra:work>","</vra:image>")
    # Change the image to a work
    vra_xml = self.datastreams["VRA"].ng_xml.to_s.sub("<vra:image","<vra:work")
    vra_xml = vra_xml.sub("</vra:image>","</vra:work>")
    self.datastreams["VRA"].content = vra_xml
    # Swap id and refid attributes in the new image reference
    node_set = self.datastreams[ "VRA" ].ng_xml.xpath( '/vra:vra/vra:work' )
    if node_set[ 1 ]
      node_set[ 1 ].name = 'image'
      node_set[ 1 ][ 'id' ] = image_pid
      node_set[ 1 ][ 'refid' ] = image_pid
    end
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

end
