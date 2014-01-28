#!/usr/bin/evn ruby

# BE CAREFUL: If you want to run this, make sure the configs are set and un-comment the image.save
# This script will assign all image objects to the DIL institutional collection, or any Admin Policy Object you want.
# From the app's root level: rails runner -e environment lib/assign_images_to_institutional_collection.rb 

error_file = File.new('/path/to/error.log', 'w')
log_file = File.new('/path/to/log_file.log', 'w')
begin
  institutional_collection = InstitutionalCollection.find("pid_of_apo_object")  
  Multiresimage.find_each {|image|
    image.add_relationship(:is_governed_by, institutional_collection)
    image.save
    log_file.write("#{image.pid} saved\n")
  }
rescue Exception=>e
  error_file.write("Exception:#{e.message}\n")
ensure
  log_file.close
  error_file.close
end
