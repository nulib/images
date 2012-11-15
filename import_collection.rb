#!/usr/bin/evn ruby

# This is a Rails runner batch process to migrate collections from the MDID system to DIL.
# The last line of the code is what is called from the command-line.
# The collections in MDID are exported and structured in folders.  That process is manual.  Then this code traverses the
# folders and creates the collections in DIL, maintaining the same structure they had in MDID.
#
# The folder structures will work with this code and are examples of how collections can be structured. The difficult part of this process
# is maintaining the collections, subcollections, and their relationships. The "collection" lines are folders,
# the "xml" is the MDID export xml with the information about which images are in the collections, and the "subcollection" lines
# are subcollections within a collection.  Because we store information in a collection regarding it's subcollections and parent collections,
# there needs to be a way for a subcollection to kno about it's parent collection's pid.  To do so, this code updates a collection's folder name
# with it's pid after the collection is created and if it has subcollections.  Thay way, a subcollection can look at it's parent folder and know
# it's pid.  That's how this code supports as many levels of nesting as needed.
#
# Notes: 
#   Parent collections can have images (or not), along with subcollections.
#   Subcollections can also be parent collections.
#
# collection
#	xml
#	subcollection
#		xml
#
# collection
#	xml
#	
# collection
#	subcollection
#		xml
#
# collection
#	subcollection
#		subcollection
#			xml

require 'xml/xslt'
require 'fileutils'


# This is the main method of this process. This will read a folder at a specified path
# and from there it decides how to create the collections. This gets called recursively.
def read_folder(path)

  logger.debug("read folder #{path}")
  
  #if root folder of import, skip to next folder since we don't want to create a collection for that folder
  if (File.expand_path("..",path) == '/usr/local/src/dil_hydra')
    #get a listing for the root folder
    Dir.glob("#{path}/*") do |name|   
      #if item is a directory (collection), make recursive call
      if FileTest.directory? name
        #logger.debug("#{name} is directory")
        read_folder(name)
      end
    end
  
  #not the root folder
  else
    
    #if the folder has a slideshow.xml file but no subdirectory (this collection has images but no subcollections)
    if (has_xml_file?(Dir.entries(path)) and !has_directory?(path))
      #logger.debug("has xml, no subdirectory")
      
      #create the collection
      create_collection(path)
    
    #if the folder doesn't have a slideshow.xml file but has subdirectory (this collections doesn't have images but has a subcollection)
    elsif (!has_xml_file?(Dir.entries(path)) and has_directory?(path))
      #logger.debug("no xml, has subdirectory")
      
      #create the collection, get it's pid
      pid = create_collection_no_images(path)
      
      #update the folder name by appending the pid
      new_path = update_folder_name_with_pid(path, pid)
      
      #read the subcollection directory
      Dir.glob("#{new_path}/*") do |name|   
        #if it has a subcollection, read that directory
        if FileTest.directory? name
          read_folder(name)
        end
      end
    
    #if the folder has a slideshow.xml file and has subdirectory (this collections has images and has a subcollection) 
    elsif (has_xml_file?(Dir.entries(path)) and has_directory?(path))
      #logger.debug("has xml, has subdirectory")
      
      #create the collection, save the pid
      pid = create_collection(path)
     
      #update the folder name by appending the pid
      new_path = update_folder_name_with_pid(path, pid)
      
      #read the subcollection directory
      Dir.glob("#{new_path}/*") do |name|   
        if FileTest.directory? name
          read_folder(name)
        end
      end #end block
      
    end #end if-else
  end # end if-else
end

#This method will create a collection that doesn't have any images (it will have subcollections)
def create_collection_no_images(folder_name)
  logger.debug("create parent_collection: #{folder_name}")
  
  #get collection name from folder name
  begin_index = folder_name.rindex("/")
  if (begin_index.present?)
    title = folder_name.slice(begin_index+1, folder_name.length-1)
  else
    title = folder_name
  end
  
  #create new collection, update it's metadata and save
  collection = DILCollection.new()
  collection.apply_depositor_metadata('mcs680')
  collection.edit_users=DIL_CONFIG['admin_staff']
  collection.set_collection_type('dil_collection')
  collection.descMetadata.title = title
  collection.save!
  
  #if this collection has a parent collection, get it's pid and update the RELS-EXT in both collections
  if (has_parent_collection?(folder_name))
    parent_pid = get_parent_collection_pid(folder_name)
    #logger.debug("parent pid: #{parent_pid}")
    parent_collection = DILCollection.find(parent_pid)
    parent_collection.insert_member(collection)
  end
  
  #logger.debug("New pid: #{collection.pid}")
  # return the pid of the new collection
  collection.pid
end

#This method will create a collection that has images
def create_collection(filename)
  logger.debug("create collection: #{filename}")
  
  #Use XSLT to extract needed info from MDID export xml
  xml_path = "#{filename}/slideshow.xml"
  xsl_path = "extract_collection_info_import.xsl"
  new_xml = "#{filename}/collection.xml"
  
  xslt = XML::XSLT.new()
  xslt.xml = xml_path
  xslt.xsl = xsl_path

  import_xml = xslt.serve()
  document = Nokogiri::XML(import_xml)
  title = document.xpath("importXml/title").text
  #logger.debug("title: #{title}")
  owner = document.xpath("importXml/owner").text
  #logger.debug("owner: #{owner}")
  image_pid = document.xpath("importXml/accessionNumber")

  #create new collection, update it's metadata and save
  #ToDo: refactor into method
  collection = DILCollection.new()
  collection.apply_depositor_metadata('mcs680')
  collection.edit_users = DIL_CONFIG['admin_staff']
  collection.set_collection_type('dil_collection')
  collection.descMetadata.title = title
  collection.save!
  
  #if this collection has a parent collection, get it's pid and update the RELS-EXT in both collections
  if (has_parent_collection?(filename))
    parent_pid = get_parent_collection_pid(filename)
    logger.debug("parent pid: #{parent_pid}")
    parent_collection = DILCollection.find(parent_pid)
    parent_collection.insert_member(collection)
  end
  
  #For each image in the MDID export xml, find it in DIL, and add the image to the collection, update RELS-EXT in image and collection
  image_pid.each do |image|
    
    #Query Solr using the accession number for each image
    dil_pids = ActiveFedora::SolrService.query("search_field_t:Voyager#{image.text} AND object_type_facet:Multiresimage")
    
    #If we have exactly one Solr result
    if (dil_pids.present? and dil_pids.size==1)
      logger.debug("Found DIL image")
      #get pid from Solr result
      if (dil_pids[0]["id"].present?)
        #load image object from Fedora
        image = Multiresimage.find(dil_pids[0]["id"])
        #add to collection
        collection.insert_member(image)
      else
        logger.debug("No id in solr result")
      end
    else
      logger.debug("Could not find DIL image. Acc. Num: #{image.text}")
    end
  end
  
  #logger.debug("New pid: #{collection.pid}")
  collection.pid
  
end

# This method checks to see if slideshow.xml is in the list of items in a directory
def has_xml_file?(entries_array)
  return_value = false
  
  entries_array.each do |entry|
    #logger.debug(entry)
    if (entry.match('slideshow.xml'))
      #logger.debug("HAS XML")
      return_value = true
    end
  end
  
  return_value
end

# This method checks to see if the directory path contains a subdirectory (that isn't . and .. )
def has_directory?(path)
  return_value = false
  Dir.entries(path).each do |entry|
    #logger.debug(entry)
    if (entry != "." and entry != ".." and FileTest.directory? "#{path}/#{entry}")
      return_value = true
    end
  end
  
  return_value
end

# This method checks to see if the parent folder of the directory is a collection
#### Might not need this ####
def has_parent_collection?(path)
  return_value = false
  if File.expand_path("..",path).match('\|pid\|')
    #logger.debug("has parent collection")
    return_value = true
  end
  return_value
end

# This method will get the pid from it's parent directory's folder name
def get_parent_collection_pid(path)
  path = File.expand_path("..",path)
  begin_index = path.rindex("|")
  pid = path.slice(begin_index+1, path.length-1)
  pid.gsub!("*", ":")
  pid
end

# This method will update the directory's name by appending the pid to it. Example: collectionName|pid|12345
def update_folder_name_with_pid(path, pid)
  #logger.debug("folder name: #{path}, #{pid}")
  pid.gsub!(":", "*")
  new_path = "#{path}|pid|#{pid}"
  FileUtils.mv(path, new_path)
  new_path
end

#
read_folder("/usr/local/src/dil_hydra/import")

