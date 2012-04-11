class Multiresimage < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  include Rails.application.routes.url_helpers
  
  belongs_to :collection, :class_name=> "DILCollection", :property=> :is_governed_by

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
  delegate :file_name, :to=>:properties, :unique=>true
  delegate :related_ids, :to=>:VRA, :at=>[:image, :relationSet, :imageOf, :relation_relids]

  def read_groups
    rightsMetadata.groups.map {|k, v| k if v == 'read'}.compact
  end

  # Grant read permissions to the groups specified. Revokes read permission for all other groups.
  # @param[Array] groups a list of groups
  # @example
  #  r.read_groups= ['one', 'two', 'three']
  #  r.read_groups 
  #  => ['one', 'two', 'three']
  #
  def read_groups=(groups)
    set_read_groups(groups, read_groups)
  end

  # Grant read permissions to the groups specified. Revokes read permission for
  # any of the eligible_groups that are not in groups.
  # This may be used when different users are responsible for setting different
  # groups.  Supply the groups the current user is responsible for as the 
  # 'eligible_groups'
  # @param[Array] groups a list of groups
  # @param[Array] eligible_groups the groups that are eligible to have their read permssion revoked. 
  # @example
  #  r.read_groups = ['one', 'two', 'three']
  #  r.read_groups 
  #  => ['one', 'two', 'three']
  #  r.set_read_groups(['one'], ['three'])
  #  r.read_groups
  #  => ['one', 'two']  ## 'two' was not eligible to be removed
  #
  def set_read_groups(groups, eligible_groups)
    g = rightsMetadata.groups.select {|k, v| v == 'edit'}
    (eligible_groups - groups).each do |group_name|
      #Strip permissions from groups not privided
      g[group_name] = 'none'
    end
    groups.each { |name| g[name] = 'read'}
    rightsMetadata.update_permissions("group"=>g)
  end

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
