# This model represents the images in the application. Images can be a part of user groups and institutional collections.
# It also has a relationship with vraworks. There are many technical metadata datatreams. VRA is used for descriptive metadata.
# The ":is_governed_by" is important for the institutional_collection relationship. Hydra uses that to know when to look at
# the institutional collection's permissions.
require 'dil/pid_minter'
require 'open3'

class Multiresimage < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::AccessControls::Permissions
  include Rails.application.routes.url_helpers
  include DIL::PidMinter
  include VraValidator

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


  attributes = [:titleSet_display, :title_altSet_display, :agentSet_display, :dateSet_display,
      :descriptionSet_display, :subjectSet_display, :culturalContextSet_display,
      :techniqueSet_display, :locationSet_display, :materialSet_display,
      :measurementsSet_display, :stylePeriodSet_display, :inscriptionSet_display,
      :worktypeSet_display, :sourceSet_display, :relationSet_display, :techniqueSet_display, :editionSet_display, :rightsSet_display, :textrefSet_display]


  attributes.each do |att|
    has_attributes att, datastream: :VRA, multiple: false
  end

  has_attributes :file_name, datastream: :properties, multiple: false
  has_attributes :related_ids, datastream: :VRA, at: [:image, :relationSet, :imageOf, :relation_relids]
  has_attributes :preferred_related_work_pid, datastream: :VRA, at: [:image, :relationSet, :imageOf_preferred, :relation_relids], multiple: false
  has_attributes :other_related_works_pids, datastream: :VRA, at: [:image, :relationSet, :imageOf_others, :relation_relids], multiple: true
  has_attributes :pref_title, datastream: :VRA, at: [:image, :titleSet, :title_pref], multiple: false
  has_attributes :pref_relation, datastream: :VRA, at: [:image, :relationSet, :relation_preferred], multiple: false

  attr_accessor :vra_xml,
                :from_menu

  before_save :update_associated_work
  before_create :vra_save
  after_create :update_relation_set_titles

  def update_relation_set_titles
    self.relationSet_display = pref_title
    self.pref_relation = pref_title
  end

  def create_datastreams_and_persist_image_files(path, batch=false)
    file = path.split("/").last
    file_number = file.split(".tif").first
    create_and_persist_status = true

    begin
      self.create_archv_techmd_datastream( path )
      self.create_archv_exif_datastream( path )
      self.create_deliv_techmd_datastream( path )
      unless Rails.env == "test"
        create_and_persist_status = ImageMover.move_img_to_repo(self.jp2_img_name, self.jp2_img_path)
      end
      self.create_deliv_ops_datastream
      self.create_deliv_img_datastream
      self.create_archv_img_datastream

      unless Rails.env == "test"
        create_and_persist_status = ImageMover.move_img_to_repo( self.tiff_img_name, path)
      end
      self.edit_groups = [ 'registered' ]
      self.save!

      j = Multiresimage.find( self.pid )
      j.save!
    rescue StandardError => e
      Sidekiq::Logging.logger.info("standard error: #{e}")
      file_number.blank? ? "no file number" : file_number
      create_and_persist_status = "#{file_number} had a problem: #{e}"
      Sidekiq::Logging.logger.info "Deleting work and image because #{e}"

      if self
        self.vraworks.first.delete if self.vraworks.first
        self.delete
      end
    end
    create_and_persist_status
  end

  def create_vra_work(vra, current_user=nil)
    work = Vrawork.new(pid: mint_pid("dil"))

    work.edit_users = DIL_CONFIG['admin_staff']
    if current_user
      work.edit_users << current_user
      work.apply_depositor_metadata(current_user.user_key)
    end

    work.datastreams["properties"].delete
    work.datastreams["VRA"].content = vra.to_s
    work.save

    #These have to be called after a save otherwise they'll try to reference a bunch of null objects
    work.add_relationship(:has_image, "info:fedora/#{self.pid}")
    work.update_ref_id(work.pid)
    work.update_relation_set(self.pid)

    # re-validate the newly updated vra
    #MultiresimageHelper.validate_vra( work.datastreams["VRA"].content )
    self.validate_vra( work.datastreams["VRA"].content )

    work.save!
    #Sidekiq::Logging.logger.info("work.save? #{work.inspect}")
    work #you'd better
  end

  #This callback gets run on create. It'll create and associate a VraWork based on the image Vra that was given to this object
  def vra_save
    #This check will probably go away when we get rid of the synchronizer.
    #We only want this code to execute if we are getting a record from menu (as opposed to the synchronizer)
    if from_menu
      vra = Nokogiri::XML(vra_xml)
    #  Sidekiq::Logging.logger.info("vra_save #{vra.xpath("/vra:vra/vra:image").present?}")
      if vra.xpath("/vra:vra/vra:image").present?

        #set the refid attribute to the new pid
        vra.xpath("/vra:vra/vra:image" )[ 0 ][ "refid" ] = self.pid

        #add the pid to the locationset
        if vra.at_xpath("/vra:vra/vra:image/vra:locationSet/vra:location/vra:refid[@source='DIL']")
          vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:location/vra:refid[@source='DIL']")[0].content = self.pid
        else
          vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:location").set_attribute('source', 'DIL')
          vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:location/vra:refid[@source='DIL']")[0].content = self.pid
        end

        #add the pid to the locationset Display
        if vra.at_xpath("/vra:vra/vra:image/vra:locationSet/vra:display").nil?
          vra.at_xpath("/vra:vra/vra:image/vra:locationSet").children.first.add_previous_sibling( Nokogiri::XML::Node.new('vra:display', vra) )
          vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:display")[0].content = "DIL:#{self.pid} ; Digital Image Library"
        else
          vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:display")[0].content.blank? ? vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:display")[0].content = "DIL:#{self.pid} ; Digital Image Library" : vra.xpath("/vra:vra/vra:image/vra:locationSet/vra:display")[0].content += " ; DIL:#{self.pid} ; Digital Image Library"
        end

        #todo: make groups be a param to the API (maybe)
        read_groups = ["registered"]
        #create the vrawork that is related to this vraimage/multiresimage
        work = create_vra_work(vra)
        vraworks << work

        # Update work reference PID
        vra.xpath( "/vra:vra/vra:work" )[ 0 ][ "id" ]    = work.pid
        vra.xpath( "/vra:vra/vra:work" )[ 0 ][ "refid" ] = work.pid

        #update vra xml to point to the new, associated work
        vra.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation')[ 0 ][ 'pref' ]   = 'true'
        vra.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation')[ 0 ][ 'relids' ] = work.pid
        vra.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation')[ 0 ][ 'type' ]   = 'imageOf'


        self.add_relationship(:has_model, "info:fedora/afmodel:Multiresimage")
        self.add_relationship(:has_model, "info:fedora/inu:imageCModel")

        #add rels-ext has_image relationship (VRAItem isImageOf VRAWork)
        self.add_relationship(:is_image_of, "info:fedora/#{work.pid}")

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

        #last thing is to validate the vra to ensure it's valid after all the modifications
        #Sidekiq::Logging.logger.info("vra to xml after all sorts modifications: #{vra.to_xml}")

        result = self.validate_vra( vra.to_xml )

        Sidekiq::Logging.logger.info("valid vra? #{result}")
        Sidekiq::Logging.logger.info("pid? #{self.pid}")


        self.datastreams[ 'VRA' ].content = vra.to_xml
        #Sidekiq::Logging.logger.info("datastreams vra content #{self.datastreams[ 'VRA' ].content}")
        self.datastreams[ 'VRA' ].content
      else
        raise "not an image type"
      end
    end
  end


  def create_archv_techmd_datastream( img_location )
    jhove_xml = create_jhove_xml( img_location )

    unless populate_datastream(jhove_xml, 'ARCHV-TECHMD', 'MIX Technical Metadata', 'text/xml')
      raise "Failed to create Jhove datastream"
    end
  end


  def create_archv_exif_datastream( img_location )
    exif_xml = `#{ Rails.root }/lib/exif.pl #{ img_location }`

    unless populate_datastream(exif_xml, 'ARCHV-EXIF', 'EXIF Technical Metadata', 'text/xml')
      raise "Failed to create EXIF datastream"
    end
  end

  def create_deliv_techmd_datastream( img_location )
    #this is stupid, it's stupid to create it more than once
    Sidekiq::Logging.logger.info("in create techmd about to create jp2 from this #{img_location}")
    begin
      create_jp2( img_location )
    rescue StandardError => e
      Sidekiq::Logging.logger.info("create jp2 failed because: #{e}")
    end
    jhove_xml = create_jhove_xml( jp2_img_path )

    unless populate_datastream(jhove_xml, 'DELIV-TECHMD', 'MIX Technical Metadata for JP2', 'text/xml')
      raise "Failed to create Jhove datastream"
    end
  end


  def create_archv_img_datastream( ds_location = nil )
    ds_location ||= "#{ DIL_CONFIG[ 'archv_url' ]}#{jp2_img_name}"
    ds_location = "http://upload.wikimedia.org/wikipedia/commons/0/0e/Haeberli_off_luv24.tif"

    unless populate_external_datastream( 'ARCHV-IMG', 'Original Image File', 'image/tiff', ds_location )
      raise "archv-img failed for some reason and i hate it"
    end
  end

  def jp2_img_name
    "#{ self.pid }.jp2".gsub( /:/, '-' )
  end


  def jp2_img_path
    Rails.root.join( 'tmp', jp2_img_name )
  end


  def tiff_img_name
    "#{ self.pid }.tif".gsub( /:/, '-' )
  end

  def create_jp2( img_location )
    return jp2_img_path if File.exist?( jp2_img_path )

    if ["development", "test"].include? Rails.env
      create_jp2_local( img_location )
    else
      create_jp2_remote( img_location )
     end

    if File.file?( jp2_img_path )
      jp2_img_path
    else
      raise "Failed to create jp2 image"
    end
  end


  def create_jp2_local( img_location )
    `convert #{img_location} -define jp2:rate=30 #{jp2_img_path}[1024x1024]`
  end

  #something is going wrong and jp2s though output says created in local tmp, they are going to /images_tmp. and don't forget to change all debugs to info
  def create_jp2_remote( img_location )
    Sidekiq::Logging.logger.info("about to create jp2 staging")
    stdout, stdeerr, status = Open3.capture3("#{DIL_CONFIG['openjpeg2_location']}bin/opj_compress -i #{img_location} -o #{jp2_img_path} -t 1024,1024 -r 15")
    Sidekiq::Logging.logger.info("out #{stdout}")
    Sidekiq::Logging.logger.info("err #{stdeerr}")
    Sidekiq::Logging.logger.info("status #{status}")
  end


  def create_deliv_ops_datastream
    #this gets called after copy of file from local tmp directory to isilon-backed location at DIL_CONFIG['jp2_location']
    jp2_location = "#{DIL_CONFIG['jp2_location']}#{jp2_img_name}"
    width_and_height = get_image_width_and_height(jp2_location)
    width = width_and_height[ :width ]
    height = width_and_height[ :height ]
    deliv_ops_xml = jp2_deliv_ops_xml( width, height, jp2_location, self.pid )

    populate_datastream( deliv_ops_xml, 'DELIV-OPS', 'SVG Datastream', 'text/xml' )
  end


  def get_image_width_and_height(img)
    if "#{Rails.env}" == "test"
      info = File.readlines("#{Rails.root}/spec/fixtures/test_jp2_info.txt")
      stdout = info.to_s
    else
      Sidekiq::Logging.logger.info("get image width and height #{DIL_CONFIG['openjpeg2_location']}")
      stdout, stdeerr, status = Open3.capture3("#{DIL_CONFIG['openjpeg2_location']}bin/opj_dump -i #{img}")
    end
    Sidekiq::Logging.logger.info("stdout #{stdout}")
    Sidekiq::Logging.logger.info("stdeerr #{stdeerr}")
    Sidekiq::Logging.logger.info("status #{status}")

    begin
      x1 = stdout.gsub(/\n/, "").gsub(/\t/, "").split("x1=", 2).last
      width = x1.split(",", 2).first

      y1 = stdout.gsub(/\n/, "").gsub(/\t/, "").split("y1=", 2).last
      height = y1.split(" ", 2).first
    rescue StandardError => e
      Sidekiq::Logging.logger.info("trouble with split #{e}")
    end

    return { width: width, height: height }
  end



    def jp2_deliv_ops_xml( width, height, rel_path, pid )
      xml = <<-EOF
  <svg:svg xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <svg:image x="0" y="0" height="#{ height }" width="#{ width }" xlink:href="/#{rel_path}/#{ jp2_img_name }"/>
  </svg:svg>
  EOF
    end


  def create_jhove_xml( img_location )
    require 'jhove_service'

    # This parameter is where the output file will go
    Sidekiq::Logging.logger.info( 'IN create_jhove_xml' )
    j = JhoveService.new( File.dirname( img_location ))
    Sidekiq::Logging.logger.debug( "jhove: #{ j }")
    xml_loc = j.run_jhove( img_location )
    jhove_xml = File.open(xml_loc).read
  end

  def create_deliv_img_datastream( ds_location = nil )
    ds_location ||= "#{ DIL_CONFIG[ 'jp2_url' ]}#{jp2_img_name}"
    unless populate_external_datastream( 'DELIV-IMG', 'Delivery Image Datastream', 'image/jp2', ds_location )
      raise "deliv-img failed. (is the jp2 location accessible?)"
    end
  end

  def create_archv_img_datastream( ds_location = nil )
    ds_location ||= "#{ DIL_CONFIG[ 'repo_url' ]}#{tiff_img_name}"

    unless populate_external_datastream( 'ARCHV-IMG', 'Original Image File', 'image/tiff', ds_location )
      raise "archv-img failed."
    end
  end


  def populate_datastream(xml, ds_name, ds_label, mime_type)
    self.datastreams[ds_name].content = xml
    self.datastreams[ds_name].dsLabel = ds_label
    self.datastreams[ds_name].mimeType = mime_type
  end


  def populate_external_datastream( ds_name, ds_label, mime_type, ds_location )
    self.datastreams[ds_name].controlGroup = 'E'
    self.datastreams[ds_name].dsLabel = ds_label
    self.datastreams[ds_name].mimeType = mime_type
    self.datastreams[ds_name].dsLocation = ds_location
  end


  def update_associated_work
    #Sidekiq::Logging.logger.info("update associated work #{vraworks.first.present?}")
    #Update the image's work (NOTE: only for 1-1 mapping, no need to update work when it's not 1-1)
    if vraworks.first.present?
      vra_work = vraworks.first
      vra_work.agentSet_display_work = agentSet_display
      vra_work.dateSet_display_work = dateSet_display
      vra_work.descriptionSet_display_work = descriptionSet_display
      vra_work.subjectSet_display_work = subjectSet_display
      vra_work.relationSet_display_work = relationSet_display
      vra_work.titleSet_display_work = titleSet_display
      vra_work.textrefSet_display_work = textrefSet_display
      vra_work.save!
    end
  end


  def preferred_related_work
    return @preferred_related_work if @preferred_related_work
    return nil unless preferred_related_work_pid.present?
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


  # Moving file from temp location to config location.  Messing server will pull from here.
  def write_out_raw
    new_filepath = temp_filename(file_name, DIL::Application.config.processing_file_path)
    File.open(new_filepath, 'wb') do |f|
      f.write raw.content
    end
    Sidekiq::Logging.logger.debug("New filepath:" + new_filepath)
    FileUtils.chmod(0644, new_filepath)
    new_filepath
  end


  #update the VRA ref id value
  def update_ref_id(ref_id)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image[@refid]')
    node_set[0].set_attribute("refid", ref_id)
    self.datastreams["VRA"].content = self.datastreams["VRA"].ng_xml.to_s
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
x      logger.error("Exception in replace_pid_in_vra:#{e.message}")
    end
  end


  def update_relation_set(work_pid)
    node_set = self.datastreams["VRA"].ng_xml.xpath('/vra:vra/vra:image/vra:relationSet/vra:relation')
    node_set[0].set_attribute("pref", "true")
    node_set[0].set_attribute("relids", work_pid)
    node_set[0].set_attribute("type", "imageOf")
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
    self.rels_ext.content.include? "isCropOf"
  end


  #get rid of this - image server will do it. proxy_image relies on it, replace
  def image_url(max_size=1600)

    src_width = self.DELIV_OPS.svg_image.svg_width.first.to_f
    src_height = self.DELIV_OPS.svg_image.svg_height.first.to_f

    ratio = [ max_size / src_width , max_size / src_height ].min

    dest_width = (src_width * ratio).to_i
    dest_height = (src_height * ratio).to_i

    "#{DIL_CONFIG['aware_region_url']}#{self.DELIV_OPS.svg_image.svg_image_path.first}&destwidth=#{dest_width}&destheight=#{dest_height}&padh=center&padv=center"
  end

  # This function removes the image from a dil_collection object, NOT an institutional collection
  def remove_from_all_dil_collections
    self.collections.each do |collection|
      collection.members.remove_member_by_pid( self.pid )
      collection.save
      self.collections.delete(collection)
    end
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
