#!/usr/bin/evn ruby

# BE CAREFUL!!!
# This script deletes all the objects using an input file to load pids
# Make sure to set the config variables!
# To run this script: rails runner

require 'fileutils'

# Configs

pids_file_path = "pids.txt"

begin
  #For each line in file, remove the datastream
  File.readlines(pids_file_path).each do |line|
    begin
      #remove newline
      line.gsub!(/\n/,'')
      
      #trim whitespace
      line.strip!
    
      #tokenize string (it's stored as: pid|accession_nbr)
      line_tokens = line.split("|")
      
      if line_tokens[0].nil? or line_tokens[0].empty?
        raise "No pid for line"
      end
      
      #load the object
      fedora_object = ActiveFedora::Base.find(line_tokens[0])
      
      if fedora_object.class == 'Multiresimage'
        
        #find it's work object and delete
        work = fedora_object.vraworks.first
        work.delete
        #delete image object
        #fedora_object.delete
      end
      
      #find xml file that needs to be run again
    
    rescue StandardError => s
      puts "StandardError: #{s.message}"
  
    rescue Exception => e
    puts "Exception: #{e.message}"
    
    end #end exception handling for loop
    
  end

rescue StandardError => s
  puts "StandardError: #{s.message}"
  
rescue Exception => e
  puts "Exception: #{e.message}"

end
