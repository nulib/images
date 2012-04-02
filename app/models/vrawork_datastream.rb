# This class should be moved out of the Hydra code

#module Hydra
class VRAWorkDatastream < ActiveFedora::NokogiriDatastream       
  include CommonVRAIndexMethods

  set_terminology do |t|
    t.root(:path=>"vra", :xmlns=>"http://www.vraweb.org/vracore4.htm", :schema=>"http://www.loc.gov/standards/vracore/vra.xsd" )
	t.vra_work(:path=>"work", :label=>"image", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
		t.titleset(:path=>"titleSet", :label=>"title set") {
			t.titleset_display(:path=>"display", :label=>"display") 
			t.titleset_title_pref(:path=>"title", :attributes=>{:pref=>"true"}) 
		}
		t.agent_set(:path=>"agentSet", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
			t.display_agent(:path=>"display", :label=>"display agent")
		}
		t.material_set(:path=>"materialSet") {
			t.material(:path=>"material", :label=>"material")
		}
		t.period_set(:path=>"stylePeriodSet") {
			t.style_period(:path=>"stylePeriod", :label=>"style period")
		}
		t.relation_set(:path=>"relationSet") {
			t.display_relation(:path=>"display", :label=>"Work")
			t.related_work(:path=>"relation", :attributes=>{:pref=>"true", :type=>"imageIs"}, :label=>"Image") {
			 t.related_work_pid(:path=>{:attribute=>"relids"}) 
			}
		}
	}
  end

	# Generates new VRA datastream
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.vra("xmlns"=>"http://www.vraweb.org/vracore4.htm", "xmlns:vra"=>"http://www.vraweb.org/vracore4.htm",
		   "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xsi:schemaLocation"=>"http://www.loc.gov/standards/vracore/vra.xsd") {
			}
      end
      return builder.doc
    end    

    
      def self.valid_child_types
        ["data", "supporting file", "profile", "lorem ipsum", "dolor"]
      end

=begin      def to_solr(solr_doc=Solr::Document.new)
        super(solr_doc)
        extract_person_full_names.each {|pfn| solr_doc << pfn }
        extract_title.each {|title| solr_doc << title }
        extract_creator.each {|creator| solr_doc << creator }
        extract_medium.each {|medium| solr_doc << medium }
        extract_period.each {|period| solr_doc << period }
		
        solr_doc << {:object_type_facet => "Vrawork"}
        solr_doc
      end
=end

    def to_solr(solr_doc=Hash.new)
      super(solr_doc)
      
      #extract_person_full_names.each_pair {|n,v| ::Solrizer::Extractor.insert_solr_field_value(solr_doc, n, v) }
      solr_doc.merge!(extract_person_full_names)
      # extract_title.each_pair {|n,v| ::Solrizer::Extractor.insert_solr_field_value(solr_doc, n, v) }
      solr_doc.merge!(extract_title)
      #extract_creator.each_pair {|n,v| ::Solrizer::Extractor.insert_solr_field_value(solr_doc, n, v) }
      solr_doc.merge!(extract_creator)
      #extract_medium.each_pair {|n,v| ::Solrizer::Extractor.insert_solr_field_value(solr_doc, n, v) }
      solr_doc.merge!(extract_medium)
      #extract_period.each_pair {|n,v| ::Solrizer::Extractor.insert_solr_field_value(solr_doc, n, v) }
      solr_doc.merge!(extract_period)
      
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, "object_type_facet", "Vrawork")
      
      solr_doc
    end

    end
