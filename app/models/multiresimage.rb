# This model represents the images in the application. Images can be a part of user groups and institutional collections.
# It also has a relationship with vraworks. There are many technical metadata datatreams. VRA is used for descriptive metadata.
# The ":is_governed_by" is important for the institutional_collection relationship. Hydra uses that to know when to look at
# the institutional collection's permissions.

class Multiresimage < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::ModelMixins::RightsMetadata
  include Rails.application.routes.url_helpers
  include DIL::PidMinter

  belongs_to :institutional_collection, :property=> :is_governed_by

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


  delegate_to :VRA, [:titleSet_display, :title_altSet_display, :agentSet_display, :dateSet_display,
      :descriptionSet_display, :subjectSet_display, :culturalContextSet_display,
      :techniqueSet_display, :locationSet_display, :materialSet_display,
      :measurementsSet_display, :stylePeriodSet_display, :inscriptionSet_display,
      :worktypeSet_display, :sourceSet_display, :relationSet_display, :techniqueSet_display, :editionSet_display, :rightsSet_display], :unique=>true

  delegate :file_name, :to=>:properties, :unique=>true
  delegate :related_ids, :to=>:VRA, :at=>[:image, :relationSet, :imageOf, :relation_relids]
  delegate :preferred_related_work_pid, :to=>:VRA, :at=>[:image, :relationSet, :imageOf_preferred, :relation_relids], :unique=>true
  delegate :other_related_works_pids, :to=>:VRA, :at=>[:image, :relationSet, :imageOf_others, :relation_relids]

  attr_accessor :vra_xml,
                :from_menu,
                :width,
                :height

  before_save :update_associated_work
  before_create :vra_save


  def create_vra_work(titleSet_display, vra, current_user=nil)
    work = Vrawork.new(pid: mint_pid("dil"))

    work.edit_users = DIL_CONFIG['admin_staff']
    if current_user
      work.edit_users << current_user
      work.apply_depositor_metadata(current_user.user_key)
    end

    work.datastreams["properties"].delete
    work.datastreams["VRA"].content = vra.to_s
    work.titleSet_display_work = titleSet_display
    work.add_relationship(:has_image, "info:fedora/#{self.pid}")

    work.save!

    #These have to be called after a save otherwise they'll try to reference a bunch of null objects
    work.update_relation_set(self.pid)
    work.update_ref_id(work.pid)
    work.save!

    work #you'd better
  end


  #This callback gets run on create. It'll create and associate a VraWork based on the image Vra that was given to this object
  def vra_save
    #This check will probably go away when we get rid of the synchronizer.
    #We only want this code to execute if we are getting a record from menu (as opposed to the synchronizer)
    if from_menu
      vra = Nokogiri::XML(vra_xml)

      vra_type = "image" if vra.xpath("/vra:vra/vra:image").present?
      if vra_type == "image"

        #set the refid attribute to the new pid
        vra.xpath("/vra:vra/vra:image", "vra"=>"http://www.vraweb.org/vracore4.htm").attr("refid", self.pid)

        #set VRA datastream to the xml document
        self.datastreams["VRA"].content = vra.to_s

        #todo: make groups be a param to the API (maybe)
        self.read_groups = ["registered"]

        #create the vrawork that is related to this vraimage/multiresimage
        work = self.create_vra_work(titleSet_display, vra)
        self.vraworks << work

        #add rels-ext has_image relationship (VRAItem isImageOf VRAWork)
        #self.add_relationship(:is_image_of, "info:fedora/#{work.pid}")

        #update vra xml to point to the new, associated work
        update_relation_set(work.pid)

        #TODO: parse the vra record for the collection record
        collection = nil

        #if this is part of an institutional collection, add that relationship
        unless collection.present?
          # Set up default institutional collection pid as being "Digital Image Library"
          institutional_collection_pid = DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]

          if collection && DIL_CONFIG["institutional_collection"][collection]
            institutional_collection_pid = DIL_CONFIG["institutional_collection"][collection]["pid"]
          end

          self.add_relationship(:is_governed_by, "info:fedora/" + institutional_collection_pid)
        end

      else
        raise "not an image type"
      end
    end
  end


  def create_jp2( img_location )
    if Rails.env == "staging"
      jp2_img = File.basename(img_location, File.extname(img_location)) + ".jp2"
      jp2_img_location = "#{Rails.root}/tmp/#{jp2_img}"
      return jp2_img_location if File.exist?( jp2_img_location )

      `LD_LIBRARY_PATH=#{Rails.root}/lib/awaresdk/lib/`
      `export LD_LIBRARY_PATH`
      `/lib/awaresdk/bin/j2kdriver -i #{img_location} -t jp2 --tile-size 1024 1024 -R 30 -o #{jp2_img_location}`
      if $?.to_i == 0 && File.file?(jp2_img_location)
        jp2_img_location
      else
        raise "Failed to create jp2 image"
      end
    else
      jp2_img = File.basename(img_location, File.extname(img_location)) + ".jp2"
      jp2_img_location = "#{Rails.root}/tmp/#{jp2_img}"
      return jp2_img_location if File.exist?( jp2_img_location )

      `convert #{img_location} -define jp2:rate=30 '#{jp2_img_location}[1024x1024]'`

      # The shell command above doesn't return any indicator about success or failure, so we need to see if the jp2 file has actually been created before continuing
      if File.file?(jp2_img_location)
        # copy the jp2 file to wherever we need it to reside for fedora
        # that location should be the ds_location that gets passed to populate_external_datastream
        jp2_img_location
      else
        raise "Failed to create jp2 image"
      end

    end
  end


  def create_deliv_ops_datastream( img_location )
#    require 'net/ssh'
    require 'net/scp'

# FROM ingest_processing_new.sh
# imageWidth=$(cat $image_xml |  sed -n "s:.*<imageWidth>\(.*\)</imageWidth.*$:\1:p" | head -n 1)
# imageHeight=$(cat $image_xml |  sed -n "s:.*<imageHeight>\(.*\)</imageHeight.*$:\1:p" | head -n 1)
# imageServerRelativePath=$(cat $image_xml |  sed -n "s:.*<imageServerRelativePath>\(.*\)</imageServerRelativePath.*$:\1:p" | head -n 1)
#

    jp2 = create_jp2( img_location )
    width_and_height = get_image_width_and_height
    width = width_and_height[ :width ]
    height = width_and_height[ :height ]
    ansel_location = DIL_CONFIG['ansel_location']
    deliv_ops_xml = jp2_deliv_ops_xml( width, height, ansel_location, self.pid )

    # Move jp2 file to ansel
    Net::SCP.upload!( "ansel.library.northwestern.edu",
                      DIL_CONFIG['ssh_user'],
                      jp2,
                      ansel_location,
                      ssh: { password: DIL_CONFIG['ssh_pw'] } )

    populate_datastream( deliv_ops_xml, 'DELIV-OPS', 'SVG Datastream', 'text/xml' )
  end



  def jp2_deliv_ops_xml( width, height, rel_path, pid )
    rel_path = rel_path.chop if rel_path.end_with?( '/' )
    xml = <<-EOF
      <svg:svg xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <svg:image x="0" y="0" height="#{ height }" width="#{ width }" xlink:href="#{ rel_path }/#{ pid }.jp2"/>
      </svg:svg>
    EOF
  end



  def get_image_width_and_height
    unless Nokogiri::XML( self.datastreams[ 'DELIV-TECHMD' ].content )
      raise "Problem with DELIV-TECHMD datastream (maybe it doesn't exist?)"
    end
    jhove_xml = Nokogiri::XML( self.datastreams[ 'DELIV-TECHMD' ].content )
    width = jhove_xml.at_xpath( '//mix:imageWidth', :mix => 'http://www.loc.gov/mix/v10' ).content
    height = jhove_xml.at_xpath( '//mix:imageHeight', :mix => 'http://www.loc.gov/mix/v10' ).content
    return { width: width, height: height }
  end


  def create_jhove_xml( img_location )
    require 'jhove_service'

    # This parameter is where the output file will go
    j = JhoveService.new( File.dirname( img_location ))
    xml_loc = j.run_jhove( img_location )
    jhove_xml = File.open(xml_loc).read
  end



  def create_deliv_techmd_datastream( img_location )
    jp2_img_location = create_jp2( img_location )

    jhove_xml = create_jhove_xml( jp2_img_location )

    unless populate_datastream(jhove_xml, 'DELIV-TECHMD', 'MIX Technical Metadata for JP2', 'text/xml')
      raise "Failed to create Jhove datastream"
    end
  end



  def create_archv_techmd_datastream( img_location )
    jhove_xml = create_jhove_xml( img_location )

    unless populate_datastream(jhove_xml, 'ARCHV-TECHMD', 'MIX Technical Metadata', 'text/xml')
      raise "Failed to create Jhove datastream"
    end
  end



  def create_archv_exif_datastream( img_location )
    # run perl script on raw exif data
    # output file

    exif_xml = `#{ Rails.root }/lib/exif.pl #{ img_location }`

    unless populate_datastream(exif_xml, 'ARCHV-EXIF', 'EXIF Technical Metadata', 'text/xml')
      raise "Failed to create EXIF datastream"
    end
  end


  def populate_datastream(xml, ds_name, ds_label, mime_type)
    self.datastreams[ds_name].content = xml
    self.datastreams[ds_name].dsLabel = ds_label
    self.datastreams[ds_name].mimeType = mime_type
  end


  def populate_external_datastream( ds_name, ds_label, mime_type, ds_location )

    self.datastreams[ds_name].dsLabel = ds_label
    self.datastreams[ds_name].dsLocation = ds_location
    self.datastreams[ds_name].mimeType = mime_type
    self.datastreams[ds_name].controlGroup = 'E'

  end


  def update_associated_work
    #Update the image's work (NOTE: only for 1-1 mapping, no need to update work when it's not 1-1)
    if vraworks.first.present?
      vra_work = vraworks.first
      vra_work.agentSet_display_work = agentSet_display
      vra_work.dateSet_display_work = dateSet_display
      vra_work.descriptionSet_display_work = descriptionSet_display
      vra_work.subjectSet_display_work = subjectSet_display
      vra_work.relationSet_display_work = relationSet_display
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


  # Moving file from temp location to config location.  Messing server will pull from here.
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
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image[@refid]')
    node_set[0].set_attribute("refid", ref_id)
    self.datastreams["VRA"].content = self.datastreams["VRA"].ng_xml.to_s
    #self.datastreams["VRA"].dirty = true
  end


  #replace the VRA locationSet_display value
  def replace_locationset_display_pid(old_pid, new_pid)
    self.VRA.locationSet_display = [self.VRA.locationSet_display[0].gsub(old_pid, new_pid)]
  end


  #replace the VRA locationSet location value
  def replace_locationset_location_pid(new_pid)
    node_set = self.datastreams["VRA"].find_by_terms("/vra:vra/vra:image/vra:locationSet/vra:location/vra:refid[@source='DIL']")
    node_set[0].content = new_pid
    self.datastreams["VRA"].content = self.datastreams["VRA"].ng_xml.to_s
    #self.datastreams["VRA"].dirty = true
  end


  #replace every instance of old pid with new pid in VRA
  def replace_pid_in_vra(old_pid, new_pid)
    begin
      update_ref_id(new_pid)
      replace_locationset_display_pid(old_pid, new_pid)
      replace_locationset_location_pid(new_pid)
    rescue Exception => e
      logger.error("Exception in replace_pid_in_vra:#{e.message}")
    end
  end


  def update_relation_set(work_pid)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation')
    node_set[0].set_attribute("pref", "true")
    node_set[0].set_attribute("relids", work_pid)
    node_set[0].set_attribute("type", "imageOf")
    node_set[0].set_attribute("label", "Image")
    self.datastreams["VRA"].content = self.datastreams["VRA"].ng_xml.to_s
    #self.datastreams["VRA"].dirty = true
  end


  def get_work_pid
    self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation/@relids')
  end


  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)
    solr_doc["title_display"] = solr_doc["title_display"].first if solr_doc['title_display'].kind_of? Array

   # If the image "is_governed_by" an InstitutionalCollection object, get that object's unit name and title.
   # It needs to be indexed (with a facet) with the image. The title and unit name are stored in the
   # descMetadata datastream.

   if self.institutional_collection.present?
     institutional_collection = InstitutionalCollection.find(self.institutional_collection.pid)
     unit_name, collection_title = institutional_collection.title.split("|")
     solr_doc["institutional_collection_unit_ssim"] = unit_name
     solr_doc["institutional_collection_unit_facet"] = unit_name
     solr_doc["institutional_collection_title_facet"] = collection_title
     solr_doc["institutional_collection_title_ssim"] = collection_title
   end

   solr_doc
  end


  ## Checks if this image is a crop
  def is_crop?
    self.RELS_EXT.content.include? "isCropOf"
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
