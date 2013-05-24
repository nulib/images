# This class should be moved out of the Hydra code

class VRAImageDatastream < ActiveFedora::NokogiriDatastream       
  include CommonVRAIndexMethods

  set_terminology do |t|
    t.root(:path=>"vra", :xmlns=>"http://www.vraweb.org/vracore4.htm", :schema=>"http://www.loc.gov/standards/vracore/vra.xsd" )
	t.vra_image(:path=>"image", :label=>"image", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
		t.titleSet(:path=>"titleSet", :label=>"title set") {
			t.titleSet_display(:path=>"display", :label=>"display") 
			t.titleSet_title_pref(:path=>"title", :attributes=>{:pref=>"true"}) 
		}
		t.agentSet(:path=>"agentSet", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
			t.agentSet_display(:path=>"display", :label=>"display agent")
		}
		t.dateSet(:path=>"dateSet", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
			t.dateSet_display(:path=>"display", :label=>"display date")
		}
		t.descriptionSet(:path=>"descriptionSet", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
			t.descriptionSet_display(:path=>"display", :label=>"display description")
		}
		t.subjectSet(:path=>"subjectSet") {
			t.subjectSet_display(:path=>"display", :label=>"display subject")
			t.subject(:path=>"subject", :label=>"subject") {
				t.subject_term(:path=>"term", :label=>"term")
			}
		}

	    t.relationSet(:path=>"relationSet") {
		  t.relationSet_display(:path=>"display", :label=>"Work")
		  t.relation_preferred(:path=>"relation", :attributes=>{:pref=>"true", :type=>"imageOf"}, :label=>"Preferred Work") {
			t.relation_type(:path=>{:attribute=>"type"})
			t.relation_relids(:path=>{:attribute=>"relids"})
			t.relation_href(:path=>{:attribute=>"href"})
		  }
		  t.relation_imageOf(:path=>"relation", :attributes=>{:type=>"imageOf"}, :label=>"Image of Work") {
			t.relation_type(:path=>{:attribute=>"type"})
			t.relation_relids(:path=>{:attribute=>"relids"})
			t.relation_href(:path=>{:attribute=>"href"})
		  }
		  t.relation(:path=>"relation", :label=>"Work") {
			t.relation_type(:path=>{:attribute=>"type"})
			t.relation_relids(:path=>{:attribute=>"relids"})
			t.relation_href(:path=>{:attribute=>"href"})
		  }
		}

#		t.relation_set(:path=>"relationSet") {
#			t.display_relation(:path=>"display", :label=>"Work")
#			t.preferred_related_work(:path=>"relation", :attributes=>{:pref=>"true", :type=>"imageOf"}, :label=>"Work") {
#			 t.preferred_related_work_pid(:path=>{:attribute=>"relids"}) 
#			}
#			t.related_work(:path=>"relation", :attributes=>{:type=>"imageOf"}, :label=>"Work") {
#			 t.related_work_pid(:path=>{:attribute=>"relids"}) 
#			}
#		}
	}

	t.vra_work(:path=>"work", :label=>"image", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
		t.titleset(:path=>"titleSet", :label=>"title set") {
			t.titleSet_display(:path=>"display", :label=>"display") 
			t.titleset_title_pref(:path=>"title", :attributes=>{:pref=>"true"}) 
		}
		t.agent_set(:path=>"agentSet", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
			t.display_agent(:path=>"display", :label=>"display agent")
		}
		t.material_set(:path=>"materialSet") {
			t.material(:path=>"material", :label=>"material")
		}
		t.period_set(:path=>"stylePeriodSet") {
			t.display_style_period(:path=>"display", :label=>"display style period")
			t.style_period(:path=>"stylePeriod", :label=>"style period")
		}
		t.subject_set(:path=>"subjectSet") {
			t.subject(:path=>"subject", :label=>"subject") {
				t.subject_term(:path=>"term", :label=>"term")
			}
		}
		t.relation_set(:path=>"relationSet") {
			t.display_relation(:path=>"display", :label=>"Work")
			t.related_work(:path=>"relation", :attributes=>{:pref=>"true", :type=>"imageIs"}, :label=>"Image") {
			 t.related_work_pid(:path=>{:attribute=>"relids"}) 
			}
		}
	}
	
	t.titleSet_display(:proxy=>[:vra_image, :titleSet, :titleSet_display])
	t.agentSet_display(:proxy=>[:vra_image, :agentSet, :agentSet_display])
	t.dateSet_display(:proxy=>[:vra_image, :dateSet, :dateSet_display])
	t.descriptionSet_display(:proxy=>[:vra_image, :descriptionSet, :descriptionSet_display])
	t.subjectSet_display(:proxy=>[:vra_image, :subjectSet, :subjectSet_display])
	
  end

     # Adds VRA image record to VRA
	 def add_image(image_node)
	  nodeset = self.find_by_terms(:vra)
	  image_node.first.add_namespace_definition("vra","http://www.vraweb.org/vracore4.htm")
	  nodeset.first.add_child(image_node)
      self.content = self.ng_xml.to_s
      return nodeset
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

	# Generates VRA Image
    def self.image_template item
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.image(:xmlns=>"http://www.vraweb.org/vracore4.htm") {
		   xml.titleSet {
				xml.display
				xml.title(:pref=>"true")
		}
		   xml.relationSet {
				xml.display
				xml.relation(:type=>"imageOf", :pref=>"true", :label=>"Work")
		   }
        }
      end
      return builder.doc
    end    
    
      # Inserts a new vra_image
    def insert_vra_image(parms)
	  node = Hydra::VRAImage.image_template({:title => parms[:title]}).root()
	  nodeset = self.find_by_terms(:vra)
      unless nodeset.nil?
		self.ng_xml.root.add_child(node)
        self.content = self.ng_xml.to_s
      end
      return node
     end
	
    
      def self.valid_child_types
        ["data", "supporting file", "profile", "lorem ipsum", "dolor"]
      end

=begin      def to_solr(solr_doc=Solr::Document.new)
        super(solr_doc)
        #extract_person_full_names.each {|pfn| solr_doc << pfn }
        extract_person_full_names.each {|pfn| solr_doc.merge(pfn) }
        #extract_title.each {|title| solr_doc << title }
        extract_title.each {|title| solr_doc.merge(title) }
        #extract_creator.each {|creator| solr_doc << creator }
        extract_creator.each {|creator| solr_doc.merge(creator) }
        #extract_medium.each {|medium| solr_doc << medium }
        extract_medium.each {|medium| solr_doc.merge(medium) }
        #extract_period.each {|period| solr_doc << period }
        extract_period.each {|period| solr_doc.merge(period) }
    
    	#solr_doc << {:object_type_facet => "Multiresimage"}
        solr_doc.merge({:object_type_facet => "Multiresimage"})
        solr_doc
=end      end
      
     def to_solr(solr_doc=Hash.new)
      super(solr_doc)
      
      solr_doc.merge!(extract_image_title_display)
      solr_doc.merge!(extract_image_agent_display)
      solr_doc.merge!(extract_image_date_display)
      solr_doc.merge!(extract_image_description_display)
      solr_doc.merge!(extract_image_subject_display)
      solr_doc.merge!(extract_image_relations)
      
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, "object_type_facet", "Multiresimage")
      
      solr_doc
    end

    end
