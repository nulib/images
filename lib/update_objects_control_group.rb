#!/usr/bin/evn ruby

# The controlGroup for a datastream cannot be changed after the datastream is created.
# In order to change the contolGroup, you need to copy the content of the ds, delete the ds, then
# re-create the ds with the old content and the new controlGroup.  Note: This deletes all audit trail
# for the datastream.  We are running this locally and in staging.

# List of datastreams to change controlGroup to M
datastreams = ["ARCHV_TECHMD", "ARCHV_EXIF", "DELIV_TECHMD"]

# For each image object 
Multiresimage.find_each {|image|
  
  # For each datastream
  datastreams.each {|ds_name|
    # If the object has the datastream with a controlGroup that isn't "M"
    if image.send(ds_name).present? and image.send(ds_name).controlGroup != "M"
 
      begin
        #get the xml from the ds
        techmd_xml = image.send(ds_name).content
  
        #delete the ds
        image.send(ds_name).delete
  
        #save the image
        image.save
  
        #reload the image
        image = Multiresimage.find(image.pid)
        
        #set the content of the ds to the previous content
        image.send(ds_name).content = techmd_xml 
        
        #set the controlGroup
        image.send(ds_name).controlGroup="M"
        
        #save the ds
        image.save
        
        puts "Updated #{ds_name} for #{image.pid}"
        
      rescue Exception => e
       puts e.message
      end
   else
    puts "No update to #{ds_name} for #{image.pid}"
  end
  }
}

