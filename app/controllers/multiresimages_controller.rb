class MultiresimagesController < ApplicationController
  include Hydra::AssetsControllerHelper
  include Blacklight::SolrHelper
  include MultiresimageHelper
  
  respond_to :html, :xml
  
	def set_format
	  request.format = 'xml'
	end

  def upload_test
    test = "test"
  end
  
  # Get SVG for id
  def get_svg
    #af_model = retrieve_af_model('Multiresimage')
	#source_fedora_object = af_model.find(params[:id])
	#source_svg_ds = source_fedora_object.datastreams_in_memory["DELIV-OPS"]   
	#@svg=source_svg_ds.to_xml()
	#debugger
	source_fedora_object = Multiresimage.find(params[:id])
	@svg = (source_fedora_object.datastreams["DELIV-OPS"]).content()
	#debugger
	respond_to do |wants|
	   #wants.xml  { render "svg" }
	   wants.xml  { render :xml => @svg }
	end
   end
 
   # Get Aware's HTML view of the image for screen scraping geometry
   def aware_details
 	@aware_details_url = "http://www.example.com/path";
   end

  # Get tile from Aware
  def aware_tile
    #debugger
	tile_url = "http://www.example.com/path"
#	tile = Net::HTTP.get_response(URI.parse(tile_url)).body
	send_data Net::HTTP.get_response(URI.parse(tile_url)).body, :type => 'image/jpeg', :disposition => 'inline'
  end

   # Create new crop from svg post
   def create_post
   
	# Get the new crop boundaries
	x=params['rect']['x']
	y=params['rect']['y']
	width=params['rect']['width']
	height=params['rect']['height']

   end
   
   
   def edit
     @multiresimage = Multiresimage.find(params[:id]) 
     #respond_to do |format|
      #format.html
      #format.xml {render :xml => @multiresimage.to_xml}
     #end
   end
   
   
   def show
     @multiresimage = Multiresimage.find(params[:id])
     #vra_image_ds = @multiresimage.datastreams["VRA"]
     #debugger
     #work_pid=vra_image_ds.find_by_terms(:vra_image, :relation_set, :related_work, :related_work_pid) 
	 #work_pid=work_pid[0]
	 #work_pid=work_pid.content
	 #debugger
	 #work_af_model = retrieve_af_model('Vrawork')
	 #@vra_work = Vrawork.find(work_pid)
	 #debugger
	 #@vra_work_ds = @vra_work.datastreams["VRA"]
	 #debugger
	 #@fedora_work_object = work_af_model.find(work_pid) 
     #respond_to do |format|
      #format.html
      #format.xml {render :xml => @multiresimage.to_xml}
     #end
   end
   
  def update
    @multiresimage = Multiresimage.find(params[:id])
    @multiresimage.update_attributes(params[:multiresimage])
    if @multiresimage.save
      flash[:notice] = "Saved changes to #{@multiresimage.id}"
    else
      flash[:error] = "Failed to save your changes!"
    end
    redirect_to edit_multiresimage_path(@multiresimage)
  end
   
   # Create new crop
   def create
	image_id = params[:id]

	# Get the new crop boundaries
	x=params[:x]
	y=params[:y]
	width=params[:width]
	height=params[:height]
	
    af_model = retrieve_af_model('Multiresimage')
	new_image = af_model.new
	puts "\nNEW IMAGE:" + new_image.pid + "x:" + x  + "y:" + y  + "width:" + width  + "height:" + height  + "\n"
	apply_depositor_metadata(new_image)
	set_collection_type(new_image, 'Multiresimage')

	# Get source Fedora object
	source_fedora_object = af_model.find(image_id)

	# Get source SVG datastream
	source_svg_ds = source_fedora_object.datastreams_in_memory["DELIV-OPS"]   
	
	# Get new SVG datastream
	new_svg_ds = new_image.datastreams_in_memory["DELIV-OPS"] 

	# Get source <image> for copying
	image_node = source_svg_ds.find_by_terms(:svg_image)
	
	# Add the <image> object
    new_svg_ds.add_image(image_node)

	# Update SVG
    new_svg_ds.add_rect(x, y, width, height)
	new_svg_ds.dirty = true
	new_image.save

	# Get source VRA datastream
	source_vra_ds = source_fedora_object.datastreams_in_memory["VRA"]
	source_vra_image=source_vra_ds.find_by_terms(:vra_image) 
	vra_ds = new_image.datastreams_in_memory["VRA"]   
	vra_ds.add_image(source_vra_image)
	new_image.save

	# Add image and VRA behavior via their cmodels
    new_image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
    new_image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
	new_image.save

	 respond_to do |wants|
		wants.html { redirect_to url_for(:action=>"show", :controller=>"catalog", :id=>new_image.pid) }
		wants.xml  { render :inline =>'<success pid="'+ new_image.pid + '"/>' }
	end
   end
 
  def updatecrop
	image_id = params[:id]
	
	# Get the new crop boundaries
	x=params['rect']['x']
	y=params['rect']['y']
	width=params['rect']['width']
	height=params['rect']['height']
#	x=params[:x]
#	y=params[:y]
#	width=params[:width]
#	height=params[:height]

	# Update the SVG Datastream
    af_model = retrieve_af_model('Multiresimage')
    document_fedora = af_model.find(image_id)
	svg_ds = document_fedora.datastreams_in_memory["DELIV-OPS"]   
    svg_ds.update_crop(x, y, width, height)

	# Get the new descriptive metadata
#	new_title=params['rect']['title']
#	new_title=params[:title]
#	unless new_title.nil?
#		vra_ds = document_fedora.datastreams_in_memory["VRA"]   
#		vra_ds.update_title(new_title)
#	end
	
	# Save the updated dataastreams
    document_fedora.save

#	puts "We're about to render inline in updatecrop"
	render :inline =>'<success pid="'+ image_id + '"/>'	
#	puts "We just rendered inline in updatecrop"
#	respond_to do |wants|
#		wants.html { redirect_to url_for(:action=>"show", :controller=>"catalog", :id=>image_id) }
#		wants.xml  { render :inline =>'<success pid="'+ image_id + '"/>' }
#	end

  end
  
  # This method/web service is called from other applications (Orbeon VRA Editor, migration scripts).
  # The URL to call this method/web service is http://localhost:3000/multiresimages/create_update_fedora_object.xml
  # It's expecting a pid param in the URL (it will check the VRA xml in the xml), as well as VRA xml in the POST request.
  # This method will create or update a Fedora object using the VRA xml that's included in the POST request
  
  def create_update_fedora_object
    begin #for exception handling
     
      #default return xml
      returnXml = "<response><returnCode>403</returnCode></response>"
      #if request is coming from these IP's, all other ip's will return with the 403 error xml)
      if !request.remote_ip.nil? and !request.remote_ip.empty?
	  
	    #update returnXml (this is the error xml, will be updated if success)
	    returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid/></response>"
	  
	    #read in the xml from the POST request
	    xml = request.body.read

	    #make sure xml is not nil and not empty
	    if !xml.nil? and !xml.empty? 
	      #load xml into Nokogiri XML document
	      document = Nokogiri::XML(xml)
	      vra_type = ""
	      pid = ""
	      
	      #pid might be a query param
	      #debugger
	      if !params[:pid].nil? and !params[:pid].empty?
	        pid = params[:pid]
	      end
	      
	      #determine if xml represents VRA work or VRA image by running xpath query and checking the result
	      if !document.xpath("/vra:vra/vra:work").nil? and !document.xpath("/vra:vra/vra:work").empty?
	        #debugger
	        vra_type = "work"
	        #attempt to extract the pid by running xpath query
	        if pid.nil? or pid.empty?
	          pid = document.xpath("/vra:vra/vra:work/@vra:refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
	          if pid.nil? or pid.empty?
	            pid = document.xpath("/vra:vra/vra:work/@refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
	          end
	        end
	      elsif !document.xpath("/vra:vra/vra:image").nil? and !document.xpath("/vra:vra/vra:image").empty?
	        #debugger
	        vra_type = "image"
	        #attempt to extract the pid by running xpath query
	        if pid.nil? or pid.empty?
	          pid = document.xpath("/vra:vra/vra:image/@vra:refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
	          if pid.nil? or pid.empty?
	            pid = document.xpath("/vra:vra/vra:image/@refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
	          end
	        end
	      end
	      
	      #if no pid was in the xml, then create a new Fedora object
	      if pid.nil? or pid.empty?
	        #mint a pid
	        pid = mint_pid()
	        #if pid was minted successfully
	        if !pid.nil? and !pid.empty?
	        
	          if vra_type == "image"
	            #create Fedora object for VRA Image, calls method in helper
	            #debugger
	            returnXml = create_vra_image_fedora_object(pid, document)
	          elsif vra_type == "work"
	            #create Fedora object for VRA Work, calls method in helper
	            #debugger
	            returnXml = create_vra_work_fedora_object(pid, document)	           
	          end
	        
	        end     
	
		
		  #pid was in xml so update the existing Fedora object if the object exists, or create the object if it doesn't exist
	      #(a pid might have been minted before this web service was called)
	      else
	        #if object doesn't exist in Fedora, create the object
	        if ActiveFedora::Base.find(pid).nil?
	          #create the object
	          if vra_type == "image"
	            returnXml = create_vra_image_fedora_object(pid, document)
	          elsif vra_type == "work"
	            returnXml = create_vra_work_fedora_object(pid, document)
	          end
	        else
	          #object already exists, update the object
	          returnXml = update_fedora_object(pid, xml, "VRA", "VRA")
	        end
	        
	        #if a work, get a list of it's related images, and re-index those images (because work info
	        #is indexed with the image, need to update the image index after the work index has been updated)
	        if vra_type == "work"
	          (solr_response, document_list) = get_related_images_from_controller(pid)
	          document_list.each { |i|
	            #load fedora object for the image
	            fedora_object = ActiveFedora::Base.load_instance(i.id)
	            #update it's solr index
	            fedora_object.update_index()
	          }
	        end
	     end #end pid if-else
		
       end #end xml_params if
   
     end #end request_ip if
  
   rescue ActiveFedora::ObjectNotFoundError
      #error xml
      returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"
      
    rescue Exception
      #error xml
      returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid>" + pid + "</pid></response>"
      
    ensure #this will get called even if an exception was raised
      #respond to request with returnXml
      respond_with returnXml do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end  
    end

  end #end method
  
  
  # This method/web service is called from other applications (migration scripts).
  # The URL to call this method/web service is http://localhost:3000/multiresimages/add_datastream.xml
  # It's expecting the following params in the URL: pid, ds_name, ds_label.  Also expecting xml in the POST request
  # This method will add a datastream to an existing Fedora object using the xml that's included in the POST request
  
  def add_datastream
    
    begin #for exception handling
      #default return xml
      returnXml = "<response><returnCode>403</returnCode></response>"
      
      if !request.remote_ip.nil? and !request.remote_ip.empty?
	    #update returnXml (this is the error xml, will be updated if success)
	    returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid/></response>"
	    #read in the xml from the POST request
	    xml = request.body.read
	    #make sure xml, pid, and datstream name and datastream label are not nil and not empty
	    if !xml.nil? and !xml.empty? and !params[:pid].nil? and !params[:pid].empty? and !params[:ds_name].nil? and !params[:ds_name].empty? and !params[:ds_label].nil? and !params[:ds_label].empty?
	        #calls method in helper
	        returnXml = update_fedora_object(params[:pid], xml, params[:ds_name], params[:ds_label])
       end #end xml_params if
   
     end #end request_ip if
  
   rescue ActiveFedora::ObjectNotFoundError
      #error xml
      returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + params[:pid] + "</pid></response>"
      
    rescue Exception
      #error xml
      returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid>" + params[:pid] + "</pid></response>"
      
    ensure #this will get called even if an exception was raised
      #respond to request with returnXml
      respond_with returnXml do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end  
    end

  end #end method
  
  
  # This method/web service is called from other applications (migration scripts).
  # The URL to call this method/web service is http://localhost:3000/multiresimages/add_external_datastream.xml
  # It's expecting the following params in the URL: pid, ds_name, ds_label, ds_location, mime_type.  Also expecting xml in the POST request
  # This method will create or update a Fedora object using the xml that's included in the POST request
  
  def add_external_datastream
    
    begin #for exception handling
      #default return xml
      returnXml = "<response><returnCode>403</returnCode></response>"
      if !request.remote_ip.nil? and !request.remote_ip.empty?
	    #update returnXml (this is the error xml, will be updated if success)
	    returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid/></response>"
	    #read in the xml from the POST request
	    #xml = request.body.read
	    #make sure pid, datstream name, datastream label and datastream location are not nil and not empty
	    if !params[:pid].nil? and !params[:pid].empty? and !params[:ds_name].nil? and !params[:ds_name].empty? and !params[:ds_label].nil? and !params[:ds_label].empty? and !params[:ds_location].nil? and !params[:ds_location].empty? and !params[:mime_type].nil? and !params[:mime_type].empty?
	        #calls method in helper
	        returnXml = add_external_ds(params[:pid], params[:ds_name], params[:ds_label], params[:ds_location], params[:mime_type])
       end #end xml_params if
   
     end #end request_ip if
  
   rescue ActiveFedora::ObjectNotFoundError
      #error xml
      returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"
      
    rescue Exception
      #error xml
      returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid>" + params[:pid] + "</pid></response>"
      
    ensure #this will get called even if an exception was raised
      #respond to request with returnXml
      respond_with returnXml do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end  
    end

  end #end method
  
    
  # This method/web service is called from other applications (VRA Editor).
  # The URL to call this method/web service is http://localhost:3000/multiresimages/delete_fedora_object.xml
  # It's expecting the following params in the URL: pid.
  # This method will delete a Fedora object using the pid that's included in the request
  
  def delete_fedora_object
    
    begin #for exception handling
      #default return xml
      returnXml = "<response><returnCode>403</returnCode></response>"
       if !request.remote_ip.nil? and !request.remote_ip.empty?
	    #update returnXml (this is the error xml, will be updated if success)
	    returnXml = "<response><returnCode>Error: The object was not deleted.</returnCode><pid/></response>"
	
	      if !params[:pid].nil? and !params[:pid].empty?
	        fedora_object = ActiveFedora::Base.load_instance(params[:pid])
	        fedora_object.delete
		    returnXml = "<response><returnCode>Delete successful</returnCode><pid>" + params[:pid] + "</pid></response>"
          end
     
     end #end request_ip if
  
   rescue ActiveFedora::ObjectNotFoundError
      #error xml
      returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"
      
    rescue Exception
      #error xml
      returnXml = "<response><returnCode>Error: The object was not deleted.</returnCode><pid>" + params[:pid] + "</pid></response>"
      
    ensure #this will get called even if an exception was raised
      #respond to request with returnXml
      respond_with returnXml do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end  
    end

  end #end method
  
  # This method/web service is called from other applications (VRA Editor).
  # The URL to call this method/web service is http://localhost:3000/multiresimages/clone_fedora_object.xml
  # It's expecting the following params in the URL: pid.
  # This method will clone a Fedora object using the pid that's included in the request
  
  def clone_work
    
    begin #for exception handling
      #default return xml
      
      returnXml = "<response><returnCode>403</returnCode></response>"
     
      if !request.remote_ip.nil? and !request.remote_ip.empty? 
	    #update returnXml (this is the error xml, will be updated if success)
	    returnXml = "<response><returnCode>Error: The object was not cloned.</returnCode><pid/></response>"
	    
	      if !params[:pid].nil? and !params[:pid].empty?
	        
	        pid = params[:pid]
	      
			orig_fedora_object = ActiveFedora::Base.load_instance(pid)
			  
			#mint a pid
			new_pid = mint_pid()
			  
			# create new Fedora object with minted pid
			new_fedora_object = Vrawork.new({:pid=>new_pid})
			  
			orig_xml = orig_fedora_object.datastreams["VRA"].content
	
			orig_document = Nokogiri::XML(orig_xml)
			orig_document.xpath("/vra:vra/vra:work/vra:relationSet").remove
			#orig_document.xpath("/vra:vra/vra:work/vra:locationSet").remove
			  
			display = orig_document.xpath("/vra:vra/vra:work/vra:locationSet/vra:display").text
			display = display.gsub(/DIL:.*\s/,'DIL:' + new_pid + ' ; ')
			orig_document.xpath("/vra:vra/vra:work/vra:locationSet/vra:display")[0].content = display
			  
			orig_document.xpath("/vra:vra/vra:work/vra:locationSet/vra:location/vra:refid[@source='DIL']").each do |node|
			  node.content = new_pid
			end
			  
			id_attr = orig_document.xpath("/vra:vra/vra:work/@id")
			id_attr[0].remove
			  
			#set the refid attribute to the new pid
			orig_document.xpath("/vra:vra/vra:work", "vra"=>"http://www.vraweb.org/vracore4.htm").attr("refid", new_pid)
			#refid_attr = document.xpath("/vra:vra/vra:work/@refid")
			#refid_attr[0].value = new_pid
			  
			new_fedora_object.datastreams["VRA"].content = orig_document.to_s
			new_fedora_object.save()
			  
			returnXml = "<response><returnCode>Clone successful</returnCode><pid>" + new_pid + "</pid></response>"
		  end #end if	
   
     end #end request_ip if
  
   rescue ActiveFedora::ObjectNotFoundError
      #error xml
      returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"
      
    rescue Exception
      #error xml
      returnXml = "<response><returnCode>Error: The object was not cloned.</returnCode><pid>" + pid + "</pid></response>"
      
    ensure #this will get called even if an exception was raised
      #respond to request with returnXml
      respond_with returnXml do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end  
    end

  end #end method
  
  #This method calls a method within Blacklight::SolrHelper.  It needs to invoked from a view helper, but the view helper can't invoke it
  #directly.  The view helper (multiresimage_helper) invokes this method, which invokes the get_search_results method in Blacklight::SolrHelper
  def get_solr_search_results(escaped_pid)
    (solr_response, document_list) = get_search_results(:q=>build_related_image_query("imageOf_t:#{escaped_pid}"))
    return solr_response, document_list
  end
  
  #def show
	#redirect_to url_for(:action=>"show", :controller=>"catalog", :id=>params[:id])
  #end

end
