#!/usr/bin/evn ruby

# This script gets the accession numbers for each image object (from the location_display_tesim field) by doing
# a Solr search

# Run the search query
records = ActiveFedora::SolrService.query("object_type_facet:Multiresimage", :fl=>"location_display_tesim", :rows=>250)

records.each {|record|
  begin
   
   # Need to extract accession number from string (example: United States. Illinois. Evanston ; DIL:inu:dil-6ef3b0ac-6083-4027-89a3-139322c1c2a4 ; Voyager:50760)
   # It's at the end of the string after "Voyager:"
   if record["location_display_tesim"][0].present?
    
    # Get index of last ":"
    begin_index = record["location_display_tesim"][0].rindex(":")+1
    
    # get last index of string
    end_index = record["location_display_tesim"][0].size
    
    puts "#{record["location_display_tesim"][0][begin_index,end_index]}"
   end
   rescue Exception => e
     #puts e.message
   end
}

