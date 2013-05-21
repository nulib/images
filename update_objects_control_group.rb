#!/usr/bin/evn ruby

datastreams = ["ARCHV_TECHMD", "ARCHV_EXIF", "DELIV_TECHMD"]
  
Multiresimage.find_each {|image|

  datastreams.each {|ds_name|
    if !image.send(ds_name).nil? and image.send(ds_name).controlGroup != "M"
 
      begin
        #get the xml
        techmd_xml = image.send(ds_name).content
  
        #delete the ds
        image.send(ds_name).delete
  
        #save the image
        image.save
  
        #reload the image
        image = Multiresimage.find(image.pid)
        
        image.send(ds_name).content = techmd_xml 
        
        image.send(ds_name).controlGroup="M"
        
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

