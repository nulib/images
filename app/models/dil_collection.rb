require 'json'
require 'dil/pid_minter'
require 'pry'

class DILCollection < ActiveFedora::Base

  include Hydra::ModelMethods
  include Hydra::AccessControls::Permissions
  include DIL::PidMinter
  has_and_belongs_to_many :multiresimages, :class_name=> "Multiresimage", :property=> :has_image

  ####
  # Each collection can belong to many parent collections and have many subcollections.
  # We were manually setting the RELS-EXT relationships before without the :parent_collections and :subcollections,
  # but this makes it easier to do things like collection.subcollections and collection.parent_collections for the
  # new collection UI.
  #
  # This isn't how it would be done in a DB Rails app, but it works here (RDF based)
  # Also, the has_many :subcollections didn't work correctly
  ####

  has_and_belongs_to_many :parent_collections, :class_name=> "DILCollection", :property=> :is_member_of
  has_and_belongs_to_many :subcollections, :class_name=> "DILCollection", :property=> :has_subcollection

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  has_metadata :name => "descMetadata", :type => Hydra::ModsCollection

  # Uses the Hydra modsCollection profile for collection list
  has_metadata :name => "members", :type => Hydra::ModsCollectionMembers

  has_attributes :title, datastream: :descMetadata, multiple: false
  has_attributes :owner, datastream: :members, multiple: false

  # Has a PowerPoint file
  has_file_datastream :name => "powerpoint", :label => "PowerPoint File"

  validates :title, :presence => true

  #A collection can have another collection as a member, or an image
  def insert_member(fedora_object)
    if (fedora_object.instance_of?(Multiresimage))

      #add to the members ds
      members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>'image')

      #add to the rels-ext ds
      fedora_object.add_relationship(:is_member_of, "info:fedora/#{self.pid}")
      add_relationship(:has_image, "info:fedora/#{fedora_object.pid}")

     elsif (fedora_object.instance_of?(DILCollection))

       #Can't add a collection to itself
       if (fedora_object.pid != self.pid)
         #Check to see if subcollection is already in collection
         subcollection_not_found = true
         self.subcollections.each do |subcollection|
           if (subcollection.pid == fedora_object.pid)
            subcollection_not_found = false
            break
           end
         end

        # Add subcollection if not found
        if subcollection_not_found
          #add to the members ds
          members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.title, :member_type=>'collection')

          #add to the rels-ext ds
          fedora_object.add_relationship(:is_member_of, "info:fedora/#{self.pid}")
          add_relationship(:has_subcollection, "info:fedora/#{fedora_object.pid}")
        end
      end

    end

    logger.debug("before image save #{Time.new}")
    fedora_object.save!
    logger.debug("after image save #{Time.new}")
    self.save!
    logger.debug("after collection save #{Time.new}")

  end

  #remove the member (image or subcollection) from a collection
  def remove_member_by_pid (pid)

   #will only delete out of RELS-EXT if member is only instance of that object in the collection.
   #member can appear in collection more than once, but only one shows up in RELS-EXT because of Hydra or Fedora restriction.
   number_of_times_in_collection = self.members.find_by_terms(:mods, :relatedItem, :identifier=>pid).size

   #remove from mods_collection_members datastream
   members.remove_member_by_pid(pid)

   #remove from RELS-EXT for both the member and the collection
   if number_of_times_in_collection == 1
     object_to_delete = ActiveFedora::Base.find(pid, :cast=>true)
     if object_to_delete.instance_of?(Multiresimage)
       self.remove_relationship(:has_image, object_to_delete)
       object_to_delete.remove_relationship(:is_member_of, self)
     elsif object_to_delete.instance_of?(DILCollection)
       self.remove_relationship(:has_subcollection, object_to_delete)
       object_to_delete.remove_relationship(:is_member_of, self)
     end
     object_to_delete.save!
   end

   self.save!

  end

  def export_pids_as_xml
    export_xml = "<collection>"
    self.members.find_by_terms(:mods, :relatedItem, :identifier).each do |pid|
      export_xml << "<pid>#{pid}</pid>"
    end
    export_xml << "</collection>"
    return export_xml
  end

  def get_all_images(multiresimages)
    self.members.find_by_terms(:mods, :relatedItem, :identifier).each do |pid|
      #get object from Fedora
      fedora_object = ActiveFedora::Base.find(pid.text, :cast=>:true)

      #if it's a collection, make call recursively
      if (fedora_object.instance_of?(DILCollection))
       multiresimages = fedora_object.get_all_images(multiresimages)
      #if it's an image, build the xml
      elsif (fedora_object.instance_of?(Multiresimage))
        multiresimages << Multiresimage.find(pid.text)
      end
    end
    multiresimages
  end

  def generate_powerpoint
    # Instantiate Powerpoint::Presentation object
    @deck = Powerpoint::Presentation.new

    # Track tmp_files so they can be deleted later on
    tmp_file_list = []
    multiresimages = []
    multiresimages = self.get_all_images(multiresimages)

    # Loop through DILCollection and generate pictorial slides for each image
    multiresimages.each do |image|
      # Powerpoint slide title information
      title = image.pref_title

      # URL is provided as input to local_resource_from_url method
      max_size = 1000
      url = image.image_url(max_size)
      #this needs to be fixed, image_url is no longer a viable method.


      # Create a local representation of the remote resource
      local_resource = LocalResource.new(URI.parse(url))

      # Copy the remote file for processing
      local_copy_of_remote_file = local_resource.file

      # Set the image_path for the slide
      image_path = local_copy_of_remote_file.path

      # Add the slide to the Presentation
      coords = set_coords(image_path)

      @deck.add_pictorial_slide title, image_path, coords

      tmp_file_list << local_copy_of_remote_file
    end

    begin
      # Save the Powerpoint Presentation file
      @deck.save(Rails.root.join("tmp","#{self.title}.#{Time.now.to_f}.pptx"))
      self.powerpoint.content = @deck.pptx_path
      self.powerpoint.mimeType = MIME::Types.type_for(@deck.pptx_path.basename.to_s).first.content_type
      self.save
    ensure
      # Delete each tmp_file to tidy things up
      tmp_file_list.each { |file| file.close }
      tmp_file_list.each { |file| file.unlink }
      File.delete(@deck.pptx_path) if File.exist?(@deck.pptx_path)
    end
  end


  # Add the detail or upload to their appropriate collections
  # Called from the multiresimages controller for the detail, and from the uploads controller for the upload
  class << self
  include DIL::PidMinter
    def add_image_to_personal_collection(personal_collection_search_result, collection_name, new_image, user_key)

      #If personal collection (either Details or Uploads) doesn't exist, create it and add image to it
      logger.debug("personal collection search result:" + personal_collection_search_result.to_s)
      if !personal_collection_search_result.present?

    	  #create new collection, update it's metadata and save
    	  new_collection = DILCollection.new(:pid=>mint_pid("dil-local"))
    	  new_collection.apply_depositor_metadata(user_key)
    	  logger.debug("collection_name: " << collection_name)
    	  new_collection.descMetadata.title = collection_name
    	  new_collection.save!

    	  #add image to collection (either a detail or an upload)
        new_collection.insert_member(new_image)

      #If personal collection (either Details or Uploads) does exist, add image to it
      elsif personal_collection_search_result.present?
        #get pid from array
        pid = personal_collection_search_result[0]["id"]

        #get collection object
        collection = DILCollection.find(pid)

        #add image to collection
        collection.insert_member(new_image)
      end
    end
  end

  def get_subcollections_json
    json_array = []

    numberSubcollections = nil

    #if collection has subcollections
    if self.subcollections.present? and self.subcollections.size > 0

      #for each subcollection
      self.subcollections.each do |subcollection|

        #if the subcollection has subcollections
        if subcollection.subcollections.present?
          numberSubcollections = subcollection.subcollections.size
        else
          numberSubcollections = 0
        end

        return_hash = { "title" => subcollection.title,
                        "pid" => subcollection.pid,
                        "numSubcollections" => numberSubcollections }

        json_array << return_hash
      end
    #no subcollections
    else
      json_size_hash = {"numberSubcollections"=>"0", "numberImages"=>numberImages}
      json_array = [json_size_hash]
    end

    json_array.to_json
  end

  def to_solr(solr_doc=Hash.new)
    solr_doc = super(solr_doc)

    #if collection is a top-level collection
    if (self.rels_ext.to_rels_ext.exclude? "fedora-relations-model:isMemberOf")
      value = "true"
    else
      value = "false"
    end

    parent_collection_hash = Hash["is_top_level_collection_ssim" => value]

    solr_doc = solr_doc.merge(parent_collection_hash)
    solr_doc = solr_doc.merge({"object_type_facet" => 'Collection'})
    solr_doc = solr_doc.merge({"title_ssim" => self.title})
    solr_doc = solr_doc.merge({"title_tesim" => self.title})
    solr_doc
  end

  def get_prev_img(loc = 0)
    loc = loc.to_i
    img = self.members.find_by_terms(:mods, :type => "image")[loc]
  	if img == self.members.find_by_terms(:mods, :type => "image").first
  		{ :pid => self.members.find_by_terms(:mods, :type => "image").last.search('relatedItem/identifier').first.text(), :titleSet_display => get_value_from_mods(self.members.find_by_terms(:mods, :type => "image").last.search('titleInfo/title').first), :index => self.members.find_by_terms(:mods, :type => "image").size - 1 }
  	else
  		{ :pid => self.members.find_by_terms(:mods, :type => "image")[loc - 1].search('relatedItem/identifier').first.text(), :titleSet_display => get_value_from_mods(self.members.find_by_terms(:mods, :type => "image")[loc - 1].search('titleInfo/title').first), :index => loc - 1 }
  	end
  end

  def get_next_img(loc = 0)
    loc = loc.to_i
    img = self.members.find_by_terms(:mods, :type => "image")[loc]
  	if img == self.members.find_by_terms(:mods, :type => "image").last
			{ :pid => self.members.find_by_terms(:mods, :type => "image").first.search('relatedItem/identifier').first.text(), :titleSet_display => get_value_from_mods(self.members.find_by_terms(:mods, :type => "image").first.search('titleInfo/title').first), :index => 0 }
		else
			{ :pid => self.members.find_by_terms(:mods, :type => "image")[loc + 1].search('relatedItem/identifier').first.text(), :titleSet_display => get_value_from_mods(self.members.find_by_terms(:mods, :type => "image")[loc + 1].search('titleInfo/title').first), :index => loc + 1 }
		end
  end

  def get_value_from_mods(xml = nil)
	  if xml.nil?
	    ''
    else
      xml.text()
    end
  end

  def show_navigation_elements?
    self.members.find_by_terms(:mods, :type => "image").size > 1
  end


  private

  def set_coords(image_path)
    return {} unless dimensions = FastImage.size(image_path)
    slide_width = 720

    src_width = dimensions[0].to_f
    src_height = dimensions[1].to_f

    max_size = 400

    ratio = [ max_size / src_width , max_size / src_height ].min

    dest_width = (src_width * ratio).to_i
    dest_height = (src_height * ratio).to_i

    {x: pixle_to_pt((slide_width / 2) - (dest_width / 2)), y: pixle_to_pt(120), cx: pixle_to_pt(dest_width), cy: pixle_to_pt(dest_height)}
  end

  def pixle_to_pt(px)
    px * 12700
  end

end
