class Multiresimage < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::ModelMixins::RightsMetadata
  include Rails.application.routes.url_helpers
  
  belongs_to :admin_policy, :class_name=> "AdminPolicy", :property=>:is_governed_by
  
  has_and_belongs_to_many :collections, :class_name=> "DILCollection", :property=> :is_member_of
  has_and_belongs_to_many :vraworks, :class_name => "Vrawork", :property => :is_image_of

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_file_datastream :name=>'raw', :type=>ActiveFedora::Datastream, :label=>'Raw image'
  
  # Uses the VRA profile for tracking the descriptive metadata
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

  # External datastream
  has_metadata :name => "POLICY", :type => ActiveFedora::Datastream, :controlGroup=>'E'
  
  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.field 'collection', :string
    m.field 'depositor', :string
    m.field 'file_name', :string
  end
  
  delegate_to :VRA, [:titleSet_display, :agentSet_display, :dateSet_display, 
      :descriptionSet_display, :subjectSet_display, :culturalContextSet_display, 
      :techniqueSet_display, :locationSet_display, :materialSet_display, 
      :measurementsSet_display, :stylePeriodSet_display, :inscriptionSet_display, 
      :worktypeSet_display], :unique=>true 

  delegate :file_name, :to=>:properties, :unique=>true
  delegate :related_ids, :to=>:VRA, :at=>[:image, :relationSet, :imageOf, :relation_relids]
  delegate :preferred_related_work_pid, :to=>:VRA, :at=>[:image, :relationSet, :imageOf_preferred, :relation_relids], :unique=>true
  delegate :other_related_works_pids, :to=>:VRA, :at=>[:image, :relationSet, :imageOf_others, :relation_relids]

  before_save :update_associated_work


  def update_associated_work
    #Update the image's work (NOTE: only for 1-1 mapping, no need to update work when it's not 1-1)
    if vraworks.first.present?
      vra_work = vraworks.first
      vra_work.agentSet_display_work = agentSet_display
      vra_work.dateSet_display_work = dateSet_display
      vra_work.descriptionSet_display_work = descriptionSet_display
      vra_work.subjectSet_display_work = subjectSet_display
      vra_work.titleSet_display_work = titleSet_display
      vra_work.save!
    end
  end
   
  def preferred_related_work
    return @preferred_related_work if @preferred_related_work
    return nil unless preferred_related_work_pid
		@preferred_related_work = Vrawork.find(preferred_related_work_pid)
  end

  def other_related_works
    return @other_related_works if @other_related_works
    return nil unless other_related_works_pids
		@other_related_works = []
    other_related_works_pids.each do |rel_pid|
      @other_related_works << Vrawork.find(rel_pid)
    end
    @other_related_works
  end

  def longside_max
      ds = self.DELIV_OPS
      if ds.svg_rect.empty?
        svg_height = ds.svg_image.svg_height.first.to_i
        svg_width = ds.svg_image.svg_width.first.to_i
      else
        svg_height = ds.svg_rect.svg_rect_height.first.to_i
        svg_width = ds.svg_rect.svg_rect_width.first.to_i
      end
      svg_height > svg_width ? svg_height : svg_width
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

  #update the VRA ref id value
  def update_ref_id(ref_id)
    #node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image[@refid]')
    node_set = self.datastreams["VRA"].find_by_terms('/vra:vra/vra:image[@refid]')
    node_set[0].set_attribute("refid", ref_id)
    #self.save!
  end
  
  #replace the VRA locationSet_display value
  def replace_locationset_display_pid(old_pid, new_pid)
    self.VRA.locationSet_display = [self.VRA.locationSet_display[0].gsub(old_pid, new_pid)]
  end
  
  #replace the VRA locationSet location value
  def replace_locationset_location_pid(new_pid)
    node_set = self.datastreams["VRA"].find_by_terms("/vra:vra/vra:image/vra:locationSet/vra:location/vra:refid[@source='DIL']")
    node_set[0].content = new_pid
  end
  
  #replace every instance of old pid with new pid in VRA
  def replace_pid_in_vra(old_pid, new_pid)
    update_ref_id(new_pid)
    replace_locationset_display_pid(old_pid, new_pid)
    replace_locationset_location_pid(new_pid)
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

  def to_solr(solr_doc = Hash.new, opts={}) 
    solr_doc = super(solr_doc, opts)
    solr_doc["title_display"] = solr_doc["title_display"].first if solr_doc['title_display'].kind_of? Array
    solr_doc
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
