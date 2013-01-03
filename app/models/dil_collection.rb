class DILCollection < ActiveFedora::Base
  
  include Hydra::ModelMethods
  include Hydra::ModelMixins::RightsMetadata
  require 'json'
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
  #belongs_to :parent, :class_name=> "DILCollection", :property=> :is_member_of
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  # Uses the Hydra MODS Article profile for tracking most of the descriptive metadata
  has_metadata :name => "descMetadata", :type => Hydra::ModsCollection 

  # Uses the Hydra modsCollection profile for collection list
  has_metadata :name => "members", :type => Hydra::ModsCollectionMembers 

  delegate :title, :to=>'descMetadata', :unique=>true

  validates :title, :presence => true

  #A collection can have another collection as a member, or an image
  def insert_member(fedora_object)
    if (fedora_object.instance_of?(Multiresimage))
      
      #add to the members ds
      members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>'image')
      
      #add to the rels-ext ds
      fedora_object.collections << self
      self.multiresimages << fedora_object
      #self.add_relationship(:has_image, "info:fedora/#{fedora_object.pid}")
      
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
          #fedora_object.add_relationship(:is_member_of, "info:fedora/#{self.pid}")
          fedora_object.parent_collections << self
          #self.add_relationship(:has_subcollection, "info:fedora/#{fedora_object.pid}")
      
          #logger.debug("self:#{self}")
          #logger.debug("fedora_object:#{fedora_object}")
          self.subcollections << fedora_object
          #fedora_object.parent = self
        end
      end
      
    end
    
    fedora_object.save!
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
  
  # This is used by the Export to PowerPoint feature.
  # It generates xml for each image in the collection
  def export_image_info_as_xml(email)
    export_xml = "<collection><email>#{email}</email>"
    export_xml = get_collection_xml(self, export_xml)
    export_xml << "</collection>"
    export_xml = export_xml.gsub('&', '&amp;')
    return export_xml
  end
  
  # This goes through the collection and builds the xml for each image.
  # If the object in the collection is a collection, this method gets called recursively.
  def get_collection_xml(collection, export_xml)
    logger.debug("COLLECTION XML INCREMENT" << export_xml)
    #for each member of the collection
    collection.members.find_by_terms(:mods, :relatedItem, :identifier).each do |pid|
      logger.debug("PID:" << pid)
      #get object from Fedora
      fedora_object = ActiveFedora::Base.find(pid.text, :cast=>:true)
      
      #if it's a collection, make call recursively
      if (fedora_object.instance_of?(DILCollection))
       export_xml = get_collection_xml(fedora_object, export_xml)
      #if it's an image, build the xml
      elsif (fedora_object.instance_of?(Multiresimage))
        logger.debug("PID:" << pid)
        export_xml << "<image><url>#{DIL_CONFIG['dil_fedora_url']}#{pid.text}#{DIL_CONFIG['dil_fedora_disseminator_ppt']}</url>"
        export_xml << "<metadata><title>Title: #{fedora_object.titleSet_display}</title><agent>Agent: #{fedora_object.agentSet_display}</agent><date>Date: #{fedora_object.dateSet_display}</date>" << "<description>Description: #{fedora_object.descriptionSet_display}</description><subject>Subject: #{fedora_object.subjectSet_display}</subject></metadata></image>" 
        logger.debug("export_xml debug:" << export_xml)
      end
    end #end each
    
   return export_xml
  end
  
  
  # Add the detail or upload to their appropriate collections
  # Called from the multiresimages controller for the detail, and from the uploads controller for the upload 
  def self.add_image_to_personal_collection(personal_collection_search_result, collection_name, new_image, user_key)
    
    #If personal collection (either Details or Uploads) doesn't exist, create it and add image to it
    logger.debug("personal collection search result:" + personal_collection_search_result.to_s)
    if !personal_collection_search_result.present?
      #authorize!(:create, DILCollection)
	  
	  #create new collection, update it's metadata and save
	  new_collection = DILCollection.new()
	  new_collection.apply_depositor_metadata(user_key)
	  new_collection.set_collection_type('dil_collection')
	  logger.debug("collection_name" << collection_name)
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
  
  def get_subcollections_json
    json_array = []
    if self.subcollections.present? and self.subcollections.size > 0
      #json_size_hash = {"numberSubcollections" => self.subcollections.size}
      #json_array = [json_size_hash]
      self.subcollections.each do |subcollection|
        numberSubcollections = nil
        if subcollection.subcollections.present?
          numberSubcollections = subcollection.subcollections.size
        else
          numberSubcollections = 0
        end
        json_array << {"title" => subcollection.title, "pid" => subcollection.pid, "numSubcollections" => numberSubcollections}
      end
    else
      json_size_hash = {"numberSubcollections"=>"0"}
      json_array = [json_size_hash]
    end
    json_array.to_json
  end
 
  def to_solr(solr_doc=Hash.new)
    solr_doc = super(solr_doc)
    
    #if collection is a top-level collection
    if (self.RELS_EXT.to_rels_ext.exclude? "fedora-relations-model:isMemberOf")
      value = "true"
    else
      value = "false"
    end
    
    parent_collection_hash = Hash["is_top_level_collection_s" => value]
    
    solr_doc = solr_doc.merge(parent_collection_hash)
    solr_doc = solr_doc.merge({"object_type_facet" => 'Collection'})
    solr_doc = solr_doc.merge({"title_s" => self.title})
    solr_doc
  end
 
 end
