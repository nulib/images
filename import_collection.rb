#!/usr/bin/evn ruby
# Rails runner batch process to migrate collections from the MDID system to DIL
require 'xml/xslt'
require 'fileutils'

def read_folder(path)

  logger.debug("read folder #{path}")
  
  #if root folder of import, skip to next folder
  if (File.expand_path("..",path) == '/usr/local/src/dil_hydra')
    Dir.glob("#{path}/*") do |name|   
      if FileTest.directory? name
        #logger.debug("#{name} is directory")
        read_folder(name)
      end
    end
  else
    #if has xml, no subdirectory
    if (has_xml_file?(Dir.entries(path)) and !has_directory?(path))
      logger.debug("has xml, no subdirectory")
      create_collection(path)
    #if no xml, has subdirectory
    elsif (!has_xml_file?(Dir.entries(path)) and has_directory?(path))
      logger.debug("no xml, has subdirectory")
      pid = create_collection_no_images(path)
      new_path = update_folder_name_with_pid(path, pid)
      Dir.glob("#{new_path}/*") do |name|   
        if FileTest.directory? name
          read_folder(name)
        end
      end #block
    elsif (has_xml_file?(Dir.entries(path)) and has_directory?(path))
      logger.debug("has xml, has subdirectory")
      pid = create_collection(path)
      new_path = update_folder_name_with_pid(path, pid)
      Dir.glob("#{new_path}/*") do |name|   
        if FileTest.directory? name
          read_folder(name)
        end
      end #block
    end
  end
end

def create_collection_no_images(folder_name)
  logger.debug("create parent_collection: #{folder_name}")
  # get collection name from folder name
  begin_index = folder_name.rindex("/")
  if (begin_index.present?)
    title = folder_name.slice(begin_index+1, folder_name.length-1)
  else
    title = folder_name
  end
  
  #create new collection, update it's metadata and save
  collection = DILCollection.new()
  collection.apply_depositor_metadata('mcs680')
  collection.set_collection_type('dil_collection')
  collection.descMetadata.title = title
  collection.save!
  
  if (has_parent_collection?(folder_name))
    parent_pid = get_parent_collection_pid(folder_name)
    logger.debug("parent pid: #{parent_pid}")
    parent_collection = DILCollection.find(parent_pid)
    #parent_collection.add_relationship(:has_subcollection, "info:fedora/#{collection.pid}")
    parent_collection.insert_member(collection)
    #parent_collection.save!
    #collection.add_relationship(:is_member_of, "info:fedora/#{parent_collection.pid}")
    #collection.save!
  end
  
  logger.debug("New pid: #{collection.pid}")
  collection.pid
end

def create_collection(filename)
  logger.debug("create collection: #{filename}")
  
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
  collection = DILCollection.new()
  collection.apply_depositor_metadata('mcs680')
  collection.set_collection_type('dil_collection')
  collection.descMetadata.title = title
  collection.save!
  
  if (has_parent_collection?(filename))
    parent_pid = get_parent_collection_pid(filename)
    logger.debug("parent pid: #{parent_pid}")
    parent_collection = DILCollection.find(parent_pid)
    #parent_collection.add_relationship(:has_subcollection, "info:fedora/#{collection.pid}")
    parent_collection.insert_member(collection)
    #parent_collection.save!
    #collection.add_relationship(:is_member_of, "info:fedora/#{parent_collection.pid}")
    #collection.save!
  end
  
  image_pid.each do |image|
    dil_pids = ActiveFedora::SolrService.query("search_field_t:Voyager#{image.text} AND object_type_facet:Multiresimage")
    if (dil_pids.present? and dil_pids.size==1)
      logger.debug("Found DIL image")
      if (dil_pids[0]["id"].present?)
        image = Multiresimage.find(dil_pids[0]["id"])
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

def has_parent_collection?(path)
  return_value = false
  if File.expand_path("..",path).match('\|pid\|')
    #logger.debug("has parent collection")
    return_value = true
  end
  return_value
end

def get_parent_collection_pid(path)
  path = File.expand_path("..",path)
  begin_index = path.rindex("|")
  pid = path.slice(begin_index+1, path.length-1)
  pid.gsub!("*", ":")
  pid
end

def update_folder_name_with_pid(path, pid)
  #logger.debug("folder name: #{path}, #{pid}")
  pid.gsub!(":", "*")
  new_path = "#{path}|pid|#{pid}"
  FileUtils.mv(path, new_path)
  new_path
end

#Loop through folder - method
read_folder("/usr/local/src/dil_hydra/import")

