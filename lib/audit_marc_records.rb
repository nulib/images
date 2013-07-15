# BE CAREFUL!!!
# This scripts goes through each MARC record in a directory, extracts the accession nbr and title,
# and sees if a record exists in DIL.
# Make sure to set the config variables.
# To run this script: ruby ./audit_marc_records.rb

require 'fileutils'
require 'nokogiri'
require 'open-uri'

# Configs
marc_records_path = 'path/to/folder'
log_file = File.new('/usr/local/src/dil_hydra/lib/marc_audit.log', 'w')
error_file = File.new('/usr/local/src/dil_hydra/lib/marc_audit_error.log', 'w')
success_file = File.new('/usr/local/src/dil_hydra/lib/marc_audit_success.log', 'w')
fail_file = File.new('/usr/local/src/dil_hydra/lib/marc_audit_fail.log', 'w')
api_url = "https://localhost:3000/multiresimages/get_number_of_objects?"
accession_nbr_xpath="//marc:subfield[@code='j'][1]"
title_one_xpath="//marc:datafield[@tag='245']/marc:subfield[@code='a']"
title_two_xpath="//marc:datafield[@tag='245']/marc:subfield[@code='p']"
sleep_value = 0.1

class MarcAuditException < Exception
end

begin
  #Loop through each file in directory
  Dir.glob("#{marc_records_path}/*.xml") do |file|  
    begin
      
      #read file
      marc = File.read(file)
      
      #generate Nokogiri doc
      marc_xml = Nokogiri::XML(marc)
      
      #get the accession nbr
      accession_nbr = marc_xml.xpath(accession_nbr_xpath).text
      
      if accession_nbr.nil?
        raise MarcAuditException, "#{file}|Could not find accession nbr"
      end
      
      #get the titles
      title = marc_xml.xpath(title_one_xpath).text
      title += " #{marc_xml.xpath(title_two_xpath).text}"
      
      if title.nil?
        raise MarcAuditException, "#{file}|Could not find title"
      end
      
      log_file.write("#{file}|#{accession_nbr}|#{title}")
      
      #make call to API
      uri = URI::encode("#{api_url}accessionNbr=#{accession_nbr}&title=#{title}")
      sleep(sleep_value)
      response = `curl -k \"#{uri}\"`
      
      log_file.write("|#{response}\n")
      
      if response.include? "Error"
        raise MarcAuditException, "#{file}|API error|#{response}"
      end
      
      #generate Nokogiri doc
      response_xml = Nokogiri::XML(response)
      
      nbr_objects = response_xml.xpath("/numberObjects").text
      
      if nbr_objects == 2
        log_file.write(file)
        success_file.write(file)
      elsif nbr_objects == 0
        log_file.write(file)
        fail_file.write(file)
      end
      
    rescue MarcAuditException => e
      log_file.write("MarcAuditException|#{file}|#{e.message}|#{e.backtrace}\n")
      error_file.write("MarcAuditException|#{file}|#{e.message}|#{e.backtrace}\n")
      
    rescue StandardError => s
      log_file.write("StandardError|#{file}|#{s.message}|#{s.backtrace}\n")
      error_file.write("StandardError|#{file}|#{s.message}|#{s.backtrace}\n")
  
    rescue Exception => e
      log_file.write("Exception|#{file}|#{e.message}|#{e.backtrace}\n")
      error_file.write("Exception|#{file}|#{e.message}|#{e.backtrace}\n")
    
    end #end exception handling for loop
   
   end #file loop

rescue StandardError => s
  error_file.write("StandardError|#{s.message}|#{s.backtrace}\n")
  log_file.write("StandardError|#{s.message}|#{s.backtrace}\n")
  
rescue Exception => e
  error_file.write("Exception|#{e.message}|#{e.backtrace}\n")
  log_file.write("Exception|#{e.message}|#{e.backtrace}\n")

ensure
  log_file.close
  success_file.close
  error_file.close
  fail_file.close

end

