# This script reads a file that has a list of Fedora pids (one per line)
# and reindexs the objects
# Make sure to set the config variables!
# To run the script (from root dir of app): rails runner -e development|staging|production lib/reindex_all_objects.rb

require 'fileutils'

# Configs
pids_file_path = 'path_to_file'
script_logger = Logger.new('path_to_logfile')

begin
  #For each line in file, load the object and remo
  File.readlines(pids_file_path).each do |pid|
    begin
      sleep(0.20) 
      #remove newline
      pid.gsub!(/\n/,'')
      
      #trim whitespace
      pid.strip!
     
      fedora_object = ActiveFedora::Base.find(pid)
      fedora_object.update_index
      script_logger.debug("Save successful: #{pid}")
    
    rescue StandardError => s
     script_logger.debug("StandardError: #{s.message}")
  
    rescue Exception => e
      script_logger.debug("Exception: #{e.message}")
    
    end #end exception handling for loop
    
end

rescue StandardError => s
  script_logger.debug("StandardError: #{s.message}")
  
rescue Exception => e
  script_logger.debug("Exception: #{e.message}")
  
ensure
  script_logger.close

end
