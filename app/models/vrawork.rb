class Vrawork  < ActiveFedora::Base
  include Hydra::ModelMethods
  #include ActiveFedora::Relationships
  include Hydra::AccessControls::Permissions

  before_create :change_vra_image_to_vra_work

  has_and_belongs_to_many :multiresimages, :class_name => "Multiresimage", :property=> :has_image

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  # Uses the VRA profile for tracking the descriptive metadata
  has_metadata :name => "VRA", :type => VRADatastream

  # A place to put extra metadata values
  has_metadata :name => "properties", :type => Hydra::Datastream::Properties

  # External datastream
  has_metadata :name => "POLICY", :type => ActiveFedora::Datastream, :controlGroup=>'E'


  attributes = [ :titleSet_display_work, :agentSet_display_work,
                :dateSet_display_work, :descriptionSet_display_work,
                :subjectSet_display_work, :culturalContextSet_display_work,
                :relationSet_display_work, :textrefSet_display_work ]

  attributes.each do |att|
    has_attributes att, datastream: :VRA, multiple: false
  end



  # The xml_template uses the vra:image tags when creating the vra work
  def change_vra_image_to_vra_work
    vra_xml = self.datastreams[ "VRA" ].ng_xml
    image_pid = vra_xml.xpath( '/vra:vra/vra:image' )[ 0 ][ 'refid' ]

    # Change the image to a work
    vra_image = vra_xml.xpath( '/vra:vra/vra:image' )
    vra_image[ 0 ].name = 'work'

    # Change the work reference to an image reference^M
    # Swap id and refid attributes in the new image reference
    vra_work = vra_xml.xpath( '/vra:vra/vra:work' )
    if vra_work[ 1 ]
      vra_work[ 1 ].name = 'image'
      vra_work[ 1 ][ 'id' ] = image_pid
      vra_work[ 1 ][ 'refid' ] = image_pid
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

  def self.find_by_accession_number(accession_nbr)
    # does not look for "Voyager: ..."
    ActiveFedora::SolrService.query("location_display_tesim:\"*Accession:#{accession_nbr}*\" AND object_type_facet:Vrawork")
  end

end
