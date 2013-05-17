# This class should be moved out of the Hydra code

class SVGDatastream < ActiveFedora::OmDatastream       

  set_terminology do |t|
    t.root(:path=>"svg", :xmlns=>"http://www.w3.org/2000/svg", :schema=>"http://www.w3.org/TR/2002/WD-SVG11-20020108/SVG.xsd", :index_as=>[:searchable])
  	t.svg_note(:path=>"note", :index_as=>[:searchable])
	t.svg_image(:path=>"image", :index_as=>[:searchable]) {
		t.svg_height(:path=>{:attribute=>"height"}, :index_as=>[:searchable])
		t.svg_width(:path=>{:attribute=>"width"}, :index_as=>[:searchable])
		t.svg_x(:path=>{:attribute=>"x"}, :index_as=>[:searchable])
		t.svg_y(:path=>{:attribute=>"y"}, :index_as=>[:searchable])
		t.svg_image_path(:path=>{:attribute=>"xlink:href",:xmlns=>"xlink:http://www.w3.org/1999/xlink" }, :index_as=>[:searchable])
	}
	t.svg_rect(:path=>"rect", :index_as=>[:searchable]) {
		t.svg_rect_height(:path=>{:attribute=>"height"}, :index_as=>[:searchable])
		t.svg_rect_width(:path=>{:attribute=>"width"}, :index_as=>[:searchable])
		t.svg_rect_x(:path=>{:attribute=>"x"}, :index_as=>[:searchable])
		t.svg_rect_y(:path=>{:attribute=>"y"}, :index_as=>[:searchable])
	}
  end
  

    # Update crop geometry
	  def update_crop(x, y, width, height)
		rect_node = self.find_by_terms(:svg_rect)
		if rect_node.nil?
		  rect_node = self.svg_rect_template(x, y, width, height)
		  self.ng_xml.root.add_child(rect_node)
		else
			rect_node.attr('x', x)
			rect_node.attr('y', y)
			rect_node.attr('width', width)
			rect_node.attr('height', height)
		end
        self.content = self.ng_xml.to_s
	  end

    # Add crop geometry
	  def add_rect(x, y, width, height)
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.rect(:x=>x, :y=>y, :width=>width, :height=>height)
		end
		self.ng_xml.root.add_child(builder.doc.root)
	    self.content = self.ng_xml.to_s
	  end

    # Add image 
	  def add_image(image_node)
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.image
		end
		new_image=builder.doc.root
		new_image['xlink:href']=image_node.attribute('href')
		new_image['width']=image_node.attribute('width')
		new_image['height']=image_node.attribute('height')
		self.ng_xml.root.add_child(new_image)
	    self.content = self.ng_xml.to_s
	  end

    # Add image from parameters
	  def add_image_parameters(href,width,height)
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.image
		end
		new_image=builder.doc.root
		new_image['xlink:href']=href
		new_image['width']=width
		new_image['height']=height
		new_image['x']="0"
		new_image['y']="0"
		self.ng_xml.root.add_child(new_image)
	    self.content = self.ng_xml.to_s
	  end

    # create rect 
    def self.svg_rect_template(x, y, width, height)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.rect(:x=>x, :y=>y, :width=>width, :height=>height)
	  end
      return builder.doc
    end    


	# Generates new VRA datastream
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.svg("xmlns"=>"http://www.w3.org/2000/svg", "xmlns:xlink"=>"http://www.w3.org/1999/xlink")
	  end
      return builder.doc
    end    
               
      def self.valid_child_types
        ["data", "supporting file", "profile", "lorem ipsum", "dolor"]
      end

      def to_solr(solr_doc=Solr::Document.new)
        super(solr_doc)
        #solr_doc << {:object_type_facet => "Multiresimage"}
        ::Solrizer::Extractor.insert_solr_field_value(solr_doc, "object_type_facet", "Multiresimage")
        solr_doc
        
      end

end

