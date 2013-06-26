#!/usr/bin/evn ruby

# BE CAREFUL!!!
# This script reads a file that has a list of Fedora pids (one per line)
# and removes a datastream.
# Make sure to set the config variables!
# To run this script: nohup ruby ./delete_policy_ds.rb &

require 'fileutils'
require 'net/http'

# Configs
folder_path = 'path_to_script'
pids_file_path = "#{folder_path}production_pids_local.txt"
fedora_host = 'localhost'
fedora_port = '8983'
fedora_username = 'username'
fedora_password = 'password'
datastream_name = 'datastream_name_here'

begin
  #For each line in file, remove the datastream
  File.readlines(pids_file_path).each do |pid|
    begin
     sleep(0.20) 
      #remove newline
      pid.gsub!(/\n/,'')
      
      #trim whitespace
      pid.strip!
    
      #use nethttp to delete the datastream using the Fedora API
      Net::HTTP.start(fedora_host, fedora_port) { |http|
	    req = Net::HTTP::Delete.new("/fedora/objects/#{pid}/datastreams/#{datastream_name}")
	    req.basic_auth fedora_username, fedora_password
		resp = http.request(req)

		if !resp.code.eql? "200"
          raise "Call failed: (#{resp.code}) #{datastream_name} : #{pid}"
        else
          puts "Successful call: #{datastream_name} : #{pid}"
        end
      
		}
    
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
