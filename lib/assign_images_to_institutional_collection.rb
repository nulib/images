#!/usr/bin/env ruby

# This script will assign all image objects to the DIL institutional collection,
# or any Admin Policy Object you want.

# INSTRUCTIONS: change the paramater in line 12 from "pid_of_apo_object" to the pid of
# the target InstitutionalCollection. Add the list of image pids to a txt file
# named "pids_to_assign_to_collection.txt" in the lib directory. Run with command below.

# BE CAREFUL: Make sure the configs are set and un-comment the image.save

# From the app's root level:
# rails runner -e environment lib/assign_images_to_institutional_collection.rb 

require 'fileutils'

pids_file_path = Rails.root.join( "lib", "pids_to_assign_to_collection.txt" )
log_file = File.new( Rails.root.join( "lib", "assign_to_collection.log" ), 'w' )
error_file = File.new( Rails.root.join( "lib", "assign_to_collection_error.log" ), 'w')

begin
  institutional_collection = InstitutionalCollection.find("pid_of_apo_object")
  File.readlines(pids_file_path).each do |line|
    begin

    line.gsub!(/\n/,'') # remove newline
    line.strip! # trim whitespace

    image = Multiresimage.find(line)

    if image.institutional_collection.blank?
      image.add_relationship(:is_governed_by, institutional_collection)
      #image.save
      log_file.write("#{image.pid} saved\n")
    end

    rescue Exception => e
      error_file.write("#{image.pid} not saved)\n")
    end # end exception handling for loop
  end

rescue Exception => e
  error_file.write("Exception: #{e.message}\n")

ensure
  log_file.close
  error_file.close
end
