class Multiresimage < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  include Rails.application.routes.url_helpers
  
  has_relationship "parts", :is_part_of, :inbound => true
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_file_datastream :name=>'raw', :type=>ActiveFedora::Datastream, :label=>'Raw image'
  
  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  #has_metadata :name => "MODS", :type => ModsArticleDatastream 

  # Uses the VRA profile for tracking some of the descriptive metadata
  has_metadata :name => "VRA", :type => VRADatastream 

  # Uses the SVG schema to encode jp2 image path, size, crop, and rotation
  has_metadata :name => "DELIV-OPS", :type => SVGDatastream 
  
  # External datastream
  #has_datastream :name => "ARCHV-IMG", :type => ActiveFedora::Datastream, :controlGroup=>'E'
  
  # External datastream
  #has_metadata :name => "ARCHV-EXIF", :type => ActiveFedora::Datastream, :controlGroup=>'E'
  
  # External datastream
  #has_metadata :name => "DELIV-IMG", :type => ActiveFedora::Datastream, :controlGroup=>'E'
  
  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field 'collection', :string
    m.field 'depositor', :string
    m.field 'file_name', :string
  end
  
  delegate :titleSet_display, :to=>:VRA, :unique=>true
  delegate :agentSet_display, :to=>:VRA, :unique=>true
  delegate :dateSet_display, :to=>:VRA, :unique=>true
  delegate :descriptionSet_display, :to=>:VRA, :unique=>true
  delegate :subjectSet_display, :to=>:VRA, :unique=>true
  delegate :culturalContextSet_display, :to=>:VRA, :unique=>true
  delegate :file_name, :to=>:properties, :unique=>true

  def self.create(params)
    files = params.delete(:files)
    obj = self.new
    obj.raw.content = files.first.read
    obj.raw.mimeType = files.first.content_type
    obj.file_name = files.first.original_filename
    obj.save
    obj
  end


  # return a hash of values for jQuery upload
  def to_jq_upload
    {:size => self.raw.size, :name=>file_name, :url=>multiresimage_path(self), :delete_url=>multiresimage_path(self), :delete_type=>'DELETE' }
  end
end
