#!/usr/bin/env ruby

# Author: Edgar Garcia and Mike S
# This notice along with part of this code was lifted from delete_policy_ds.rb as written by Mike Stroming

# BE CAREFUL!!!
# This script reads a file that has a list of Fedora pids (one per line)
# and checks to make sure it has all it's datastreams. There is some VRA specific code in here that
# can be commented out (getting the accession nbrs)
# Make sure to set the config variables!
require 'fileutils'
require 'net/http'

# Configs
@folder_path = '/usr/local/src/dil_hydra/'
@pids_file_path = "#{@folder_path}pid.txt"
@fedora_url = "http://localhost:8983/fedora/objects/"
@fedora_username = 'fedoraAdmin'
@fedora_password = 'fedoraAdmin'
#log for every missing datastream for each object
@missing_ds_aggregate_file = File.new('/usr/local/src/dil_hydra/lib/audit_missing_ds_aggregate.log', 'w')
#log for pids that have a missing datastream
@missing_ds_pid_file = File.new('/usr/local/src/dil_hydra/lib/audit_missing_ds_pids.log', 'w')
#log for pids that are complete objects
@complete_object_pid_file = File.new('/usr/local/src/dil_hydra/lib/audit_complete_pids.log', 'w')
@error_file = File.new('/usr/local/src/dil_hydra/lib/audit_errors.log', 'w')
@all_ds = ["RELS-EXT", "ARCHV-IMG", "DELIV-IMG", "DELIV-OPS", "ARCHV-EXIF", "ARCHV-TECHMD", "DELIV-TECHMD", "VRA", "DC", "rightsMetadata"]
@sleep_value = 0.1


# Get the accession number from the content of the VRA datastream.
# It's extracted from a node that looks like this:
#<vra:location>
#  <vra:refid source="DIL">inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26</vra:refid>
#  <vra:refid source="Voyager">16245</vra:refid>
#</vra:location>
# This method uses string manipulation instead of regex and xml parsing for performance
def get_accession_nbr(pid)
  uri = URI.parse("#{@fedora_url}#{pid}/datastreams/VRA/content")
  http = Net::HTTP.new(uri.host, uri.port)
  #build request
  request = Net::HTTP::Get.new(uri.request_uri)
  #add auth
  request.basic_auth(@fedora_username, @fedora_password)
  #run the request
  response = http.request(request)
  sleep(@sleep_value)
  accession_nbr=""
  if response.code.eql? "200"
    vra = response.body if !response.body.nil?
    #this should be easier to follow than a regex and faster than using an xml parser
    #get the index of the start and close of the Voyager node and add the nbr of characters to it to get to the end
    #of the strings
    node_start = "<vra:refid source=\"Voyager\">"
    node_end= "</vra:refid>"
    index_start_node = vra.index(node_start) + node_start.length
    index_end_node = vra.index(node_end, index_start_node) - 1
    accession_nbr = vra[index_start_node..index_end_node]
  end
  return accession_nbr
end

begin

  #For each line in file, check the datastreams
  File.readlines(@pids_file_path).each do |pid|
    begin
      object_logged = false
      #remove newline
      pid.gsub!(/\n/,'')

      #trim whitespace
      pid.strip!

      #fedora_object = ActiveFedora::Base.find(pid, :cast => true)
      
      #ALL DATASTREAMS
      @all_ds.each do |datastream|
         #build uri
         uri = URI.parse("#{@fedora_url}#{pid}/datastreams/#{datastream}")
         http = Net::HTTP.new(uri.host, uri.port)
         #build request
         request = Net::HTTP::Get.new(uri.request_uri)
         #add auth
         request.basic_auth(@fedora_username, @fedora_password)
         #run the request
         sleep(@sleep_value)
         response = http.request(request)
         
         #if the datastream is does not exist, log
         if !response.code.eql? "200"
            if object_logged 
               @missing_ds_aggregate_file.write("#{pid}|#{datastream}|#{response.code}\n")
            else
               #get accession nbr to add to log
               accession_nbr = get_accession_nbr(pid)
               #log to aggregate log and pid log
               @missing_ds_aggregate_file.write("#{pid}|#{datastream}|#{response.code}\n")
               @missing_ds_pid_file.write("#{pid}|#{accession_nbr}\n")
            end
            object_logged = true
         end
       end
       
       if !object_logged
         @complete_object_pid_file.write("#{pid}\n")
       end
    
      # Check for missing work.
    rescue StandardError => s
      @error_file.write(s.message)
    rescue Exception => e
      @error_file.write(e.message)
    end
    
  end

rescue StandardError => s
  @error_file.write(s.message)
rescue Exception => e
  @error_file.write(e.message)
ensure
  @missing_ds_aggregate_file.close
  @missing_ds_pid_file.close
  @complete_object_pid_file.close
  @error_file.close
end
