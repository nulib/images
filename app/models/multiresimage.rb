class Multiresimage < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include Rails.application.routes.url_helpers
  include Dil::RightsMetadata
  
  has_and_belongs_to_many :collections, :class_name=> "DILCollection", :property=> :is_governed_by
  has_and_belongs_to_many :vrawork, :class_name => "Vrawork", :property => :is_image_of

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_file_datastream :name=>'raw', :type=>ActiveFedora::Datastream, :label=>'Raw image'
  
  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  #has_metadata :name => "MODS", :type => ModsArticleDatastream 

  # Uses the VRA profile for tracking some of the descriptive metadata
  has_metadata :name => "VRA", :type => VRADatastream, :label=> 'VRA metadata'

  # Uses the SVG schema to encode jp2 image path, size, crop, and rotation
  has_metadata :name => "DELIV-OPS", :type => SVGDatastream, :label=>'SVG Datastream'
  
  has_metadata :name => "ARCHV-TECHMD", :type => ActiveFedora::Datastream, :label=>'Archive image technical metadata'

  has_metadata :name => "ARCHV-EXIF", :type => ActiveFedora::Datastream, :label=>'Archive image EXIF metadata'
  
  has_metadata :name => "DELIV-TECHMD", :type => ActiveFedora::Datastream, :label=>'Image technical metadata'
  
  # External datastream
  has_metadata :name => "ARCHV-IMG", :type => ActiveFedora::Datastream, :controlGroup=>'E'
  
  # External datastream
  has_metadata :name => "DELIV-IMG", :type => ActiveFedora::Datastream, :controlGroup=>'E'
  
  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
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
  delegate :techniqueSet_display, :to=>:VRA, :unique=>true
  delegate :file_name, :to=>:properties, :unique=>true
  delegate :related_ids, :to=>:VRA, :at=>[:image, :relationSet, :imageOf, :relation_relids]


  def attach_file(files)
    if files.present?
      raw.content = files.first.read
      raw.mimeType = files.first.content_type
      self.file_name = files.first.original_filename
    end
  end

  # return a hash of values for jQuery upload
  def to_jq_upload
    {:size => self.raw.size, :name=>file_name, :url=>multiresimage_path(self), :delete_url=>multiresimage_path(self), :delete_type=>'DELETE' }
  end

  def write_out_raw
    new_filepath = temp_filename(file_name, DIL::Application.config.processing_file_path)
    File.open(new_filepath, 'wb') do |f|
      f.write raw.content
    end
    logger.debug("New filepath:" + new_filepath)
    FileUtils.chmod(0644, new_filepath)
    new_filepath
  end

  def update_ref_id(ref_id)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image[@refid]')
    node_set[0].set_attribute("refid", ref_id)
    #self.save!
  end
  
  def update_relation_set(work_pid)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation')
    node_set[0].set_attribute("pref", "true")
    node_set[0].set_attribute("relids", work_pid)
    node_set[0].set_attribute("type", "imageOf")
    node_set[0].set_attribute("label", "Image")
    #self.save!
  end
  
  def get_work_pid
    self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation/@relids')
  end
  
  private

  ## Produce a unique filename that doesn't already exist.
  def temp_filename(basename, tmpdir='/tmp')
    n = 0
    begin
      tmpname = File.join(tmpdir, sprintf('%s%d.%d', basename, $$, n))
      lock = tmpname + '.lock'
      n += 1
    end while File.exist?(tmpname)
    tmpname
  end
  
end
