# BE CAREFUL!!!
# This script deletes all the objects using an input file to load pids
# Make sure to set the config variables!
# To run this script: rails runner -e environment object_cleanup.rb

require 'fileutils'

# Configs
pids_file_path = '/usr/local/src/dil_hydra/lib/pid.txt'
xml_dir_path = '/usr/local/src/dil_hydra/lib/'
#log for pids that are complete objects
log_file = File.new('/usr/local/src/dil_hydra/lib/cleanup.log', 'w')
error_file = File.new('/usr/local/src/dil_hydra/lib/cleanup_errors.log', 'w')

#For each line in file, get the pid, find the MARC xml file, delete the Fedora objects and Solr
#documents
begin
  File.readlines(pids_file_path).each do |line|
    begin
      #remove newline
      line.gsub!(/\n/,'')
      
      #trim whitespace
      line.strip!
    
      #tokenize string (it's stored as: pid|accession_nbr)
      line_tokens = line.split("|")
      
      if line_tokens[0].blank? or !line_tokens[1].blank?
        raise "Data not good"
      end
      
      
      #load the object
      fedora_object = ActiveFedora::Base.find(line_tokens[0])
      
      #find xml file that needs to be run again
      log_file.write("#{line_tokens[1]} #{xml_dir_path}")
      files = `grep -rl #{line_tokens[1]} #{xml_dir_path}`  
      
      if files.blank?
        raise "Could not find XML file"
      end
      
      if fedora_object.class == 'Multiresimage'
        
        #find it's work object and delete
        work = fedora_object.vraworks.first
        #work.delete
        #delete image object
        #fedora_object.delete
      end
      
    rescue StandardError => s
      error_file.write "StandardError: #{s.message}"
  
    rescue Exception => e
      error_file.write "Exception: #{e.message}"
    
    end #end exception handling for loop
  end

rescue StandardError => s
  puts "StandardError: #{s.message}"
  
rescue Exception => e
  puts "Exception: #{e.message}"

ensure
  log_file.close
  error_file.close

end
