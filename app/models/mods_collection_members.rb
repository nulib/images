#module Hydra
class ModsCollectionMembers < ActiveFedora::NokogiriDatastream       
  include Hydra::Datastream::CommonModsIndexMethods

  set_terminology do |t|
    t.root(:path=>"modsCollection", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd") 
		t.mods {
			t.title_info(:path=>"titleInfo") {
			  t.main_title(:path=>"title", :label=>"title")
			}
			t.relatedItem {
				t.identifier
			}
			t.title(:path=>"titleInfo/title")
		}
		
		
  end

    # Generates an empty Mods Collections (used when you call ModsCollectionMembers.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.modsCollection(:version=>"3.3", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xmlns"=>"http://www.loc.gov/mods/v3",
           "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd") {
        }
      end
      return builder.doc
    end    
 
	# Generates an empty Mods Collections (used when you call ModsCollectionMembers.new without passing in existing xml)
    def self.mods_template item
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods {
		   xml.titleInfo {
				xml.title item[:title]
		   }
		   xml.relatedItem {
	           xml.identifier item[:pid]
		   }
        }
      end
      return builder.doc
    end    
	
		     
    # Inserts a new MODS record into a modsCollection, representing a collection member
    def insert_member(parms)
	  node = ModsCollectionMembers.mods_template({:title => parms[:member_title] , :pid => parms[:member_id]}).root()
	  nodeset = self.find_by_terms(:modsCollection)
      unless nodeset.nil?
		self.ng_xml.root.add_child(node)
        self.dirty = true
      end
      return node
     end
    
      # Remove the mods entry identified by @index
	  def remove_member_by_index(member_index)
		self.find_by_terms({:mods=>member_index.to_i}).first.remove
		self.dirty = true
	  end
	  
	# Remove the mods entry identified by pid
	  def remove_member_by_pid(pid)
        #logger.debug("debug xpath: " + self.ng_xml.xpath('//mods:mods/mods:relatedItem/mods:identifier[.="' + pid + '"]', {'mods'=>'http://www.loc.gov/mods/v3'})
        #logger.debug("debug xpath" + self.ng_xml.xpath('//mods:mods/mods:relatedItem/mods:identifier[.="' + pid + '"]', {'mods'=>'http://www.loc.gov/mods/v3'}).to_s)
		#self.ng_xml.xpath('//mods:mods/mods:relatedItem/mods:identifier[.="' + pid + '"]', {'mods'=>'http://www.loc.gov/mods/v3'}).first.remove
		self.ng_xml.xpath('//mods:identifier[.="' + pid + '"]/ancestor::mods:mods', {'mods'=>'http://www.loc.gov/mods/v3'}).first.remove
	    self.dirty = true
	  end
	  
	# Moves the mods record to a different index within the datastream
	  def move_member(from_index, to_index)
	    #get node to be moved and clone it
	    moving_node = self.find_by_terms({:mods=>from_index.to_i}).first().clone()
	    #get node at to_index
	    to_node = self.find_by_terms({:mods=>to_index.to_i}).first()
	    #remove the node to be moved at it's original index
	    remove_member_by_index(from_index)
	
	    #if moving node from left to right, add moving node after the to_index node
	    if (from_index < to_index)
	      to_node.after(moving_node)
	    #moving from right to left, add moving node before the to_index node
	    else
	      to_node.before(moving_node)
	      #to_node.add_previous_sibling(moving_node)
	    end
	    
      end
    
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)
        ::Solrizer::Extractor.insert_solr_field_value(solr_doc, "object_type_facet", "Collection")
        solr_doc
      end

    end
#end
