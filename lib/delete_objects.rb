# BE CAREFUL!!!
# This script deletes objects using an input file to load pids
# THE DELETES ARE COMMENTED OUT
# Make sure to set the config variables.
# To run this script from app root: rails runner -e environment lib/delete_objects.rb

require 'fileutils'

# Configs
pids_file_path = Rails.root.join( 'pids_to_delete.txt' )
log_file = File.new( Rails.root.join( "log", "delete.log" ), 'w' )
error_file = File.new( Rails.root.join( "log", "delete_error.log" ), 'w')


#For each line in file, get the pid, find the MARC xml file, delete the Fedora objects and Solr
#documents
begin
  File.readlines(pids_file_path).each do |line|
    begin

      #remove newline
      line.gsub!(/\n/,'')

      #trim whitespace
      line.strip!

      # load the Fedora object
      log_file.puts("Working with this pid: #{line}")
      fedora_object = ActiveFedora::Base.find(line, :cast=>:true)
      if fedora_object.is_a? Multiresimage
        #find it's work object and delete
        work = fedora_object.vraworks.first
        if work.empty?
          log_file.puts("There is no work for this pid! Trying to delete the image object...")
          #fedora_object.delete
        else
          log_file.write("delete #{fedora_object.pid}|#{work.pid}\n")
          #work.delete
          #fedora_object.delete
        end
      elsif fedora_object.is_a? Vrawork
        image = fedora_object.multiresimages.first
        if image.empty?
          log_file.puts("No image for this work! Trying to delete work anyway...")
          #fedora_object.delete
        else
          log_file.write("delete #{fedora_object.pid}|#{image.pid}\n")
          #image.delete
          #fedora_object.delete
        end
      end

    rescue StandardError => s
      error_file.write "StandardError: #{s.message}\n"

    rescue Exception => e
      error_file.write "Exception: #{e.message}\n"

    end #end exception handling for loop
  end

rescue StandardError => s
  log_file.write("StandardError: #{s.message}\n")

rescue Exception => e
  log_file.write("Exception: #{e.message}\n")

ensure
  log_file.close
  error_file.close

end
