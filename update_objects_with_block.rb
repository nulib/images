#!/usr/bin/evn ruby

Multiresimage.find_each(:rows=>10000){|obj|

if !obj.datastreams["properties"].content.nil?
  obj.datastreams["rightsMetadata"].content="<rightsMetadata xmlns='http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1' version='0.1'> <copyright> <human></human> <machine> <uvalicense>no</uvalicense> </machine> </copyright> <access type='discover'> <human></human> <machine> <group>public</group> </machine> </access> <access type='read'> <human></human> <machine> <group>public</group> </machine> </access> <access type='edit'> <human></human> <machine></machine> </access> <embargo> <human></human> <machine></machine> </embargo> </rightsMetadata>"

  obj.datastreams["properties"].delete
  begin
  obj.save
  #puts "solr: "+obj.rightsMetadata.to_solr
  #obj.update_index
  puts "success"
  rescue Exception
   puts Exception.message
  end
else
  puts "already updated"
end
puts "pid:"+obj.pid
}
