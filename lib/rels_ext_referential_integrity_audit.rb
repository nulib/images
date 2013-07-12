# BE CAREFUL!!!
# This script checks that the work/image object reference in the RELS-EXT of the work/image object
# actually exists
# Make sure to set the config variables.
# To run this script: ruby ./rels_ext_referential_integrity_audit.rb

require 'fileutils'
require 'nokogiri'
require 'net/http'

# Configs
pids_file_path = '/usr/local/src/dil_hydra/lib/pid.txt'
log_file = File.new('/usr/local/src/dil_hydra/lib/ref_integrity_success.log', 'w')
ref_integrity_fail_file = File.new('/usr/local/src/dil_hydra/lib/ref_integrity_fail.log', 'w')
error_file = File.new('/usr/local/src/dil_hydra/lib/ref_integrity_error.log', 'w')
fedora_url = "http://localhost:8983/fedora/objects/"
@fedora_username = 'fedoraAdmin'
@fedora_password = 'fedoraAdmin'
#note: the nullib-rel namespace isn't in the RDF on staging, so if running on staging, remove it in line below
rels_ext_node = '/rdf:RDF/rdf:Description/nullib-rel:isImageOf/@rdf:resource'
@sleep_value = 0.1

def call_fedora_api(uri)
  uri = URI.parse(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  #build request
  request = Net::HTTP::Get.new(uri.request_uri)
  #add auth
  request.basic_auth(@fedora_username, @fedora_password)
  #run the request
  sleep(@sleep_value)
  response = http.request(request)
end

class RefIntegrityException < Exception
end

#For each line in file, get the pid, find the MARC xml file, delete the Fedora objects and Solr
#documents
begin
  File.readlines(pids_file_path).each do |pid|
    begin
      related_pid = ""
      #remove newline
      pid.gsub!(/\n/,'')
      
      #trim whitespace
      pid.strip!
      
      #get the RELS-EXT content
      response = call_fedora_api("#{fedora_url}#{pid}/datastreams/RELS-EXT/content")
      
      #get the object's rels-ext
      if response.code == '200'
        rels_ext = Nokogiri::XML(response.body)
      else
        error_file.write("#{pid}|#{response.code}")
        raise RefIntegrityException, "#{pid}\n"
      end
      
      #get the object's related pid from the rels-ext
      related_pid = rels_ext.xpath(rels_ext_node).text
      
      if related_pid.nil? or related_pid.empty?
        raise RefIntegrityException, "#{pid}\n"
      end
      
      related_pid.slice!("info:fedora/")
      
      #check to see if related pid object exists
      response = call_fedora_api("#{fedora_url}#{related_pid}")
      
      if response.code == '200'
        log_file.write("#{pid}|#{related_pid}\n")
      else
        raise RefIntegrityException, "#{pid}|#{related_pid}\n"
      end
    
    rescue RefIntegrityException => e
      ref_integrity_fail_file.write(e.message)
      
    rescue StandardError => s
      error_file.write("StandardError|#{s.message}|#{s.backtrace}\n")
  
    rescue Exception => e
      error_file.write("Exception|#{e.message}|#{e.backtrace}\n")
    
    end #end exception handling for loop
  
  end

rescue StandardError => s
  log_file.write("StandardError|#{s.message}|#{s.backtrace}\n")
  
rescue Exception => e
  log_file.write("Exception|#{e.message}|#{e.backtrace}\n")

ensure
  log_file.close
  error_file.close
  ref_integrity_fail_file.close

end

