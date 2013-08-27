# BE CAREFUL!!!
# This script deletes objects using an input file to load pids
# THE DELETES ARE COMMENTED OUT
# Make sure to set the config variables.
# To run this script from app root: rails runner -e environment /lib/delete_objects.rb

require 'fileutils'

# Configs
pids_file_path = 'path_to_pid_file'
log_file = File.new('log_file_path', 'w')
error_file = File.new('error_file_path', 'w')

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
      fedora_object = ActiveFedora::Base.find(line, :cast=>:true)
      if fedora_object.is_a? Multiresimage
        #find it's work object and delete
        work = fedora_object.vraworks.first
        log_file.write("delete #{fedora_object.pid}|#{work.pid}\n")
        #work.delete
        #fedora_object.delete
      elsif fedora_object.is_a? Vrawork
        image = fedora_object.multiresimages.first
        log_file.write("delete #{fedora_object.pid}|#{image.pid}\n")
        #image.delete
        #fedora_object.delete
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
