module MultiresimageHelper
 
	#include Blacklight::SolrHelper
	#include Hydra::AccessControlsEnforcement
	
  def mint_pid()
    pid_mint_url="http://www.example.com/cgi-bin/drupal_to_repo/mint_pid.cgi?prefix=dil-"
    pid = Net::HTTP.get_response(URI.parse(pid_mint_url)).body.strip
    return pid
  end
  
  def get_work(work_pid) 
	work_af_model = retrieve_af_model('Vrawork')
	@fedora_work_object = work_af_model.find(work_pid) 
  end
  
  def get_work_object(work_pid)
	@fedora_work_object = Vrawork.find(work_pid)
	return @fedora_work_object
  end

  def get_work_sets(work_pid) 
	work_af_model = retrieve_af_model('Vrawork')
	fedora_work_object = work_af_model.find(work_pid) 
	vra_ds = fedora_work_object.datastreams_in_memory["VRA"]
	vra_work=vra_ds.find_by_terms(:vra_work) 
	
#	vra_sets = Hash.new
#	vra_work.children.each do |vraset| 
#		display = vraset.xpath('.//vra:display', { 'vra' => 'http://www.vraweb.org/vracore4.htm' })
#		if ! vraset.name.partition("Set")[1].empty?
#			vra_sets{vraset.name.partition("Set")[0] => display}
#		end
#	end
#	vra_work
  end

  #use this method instead of get_related_images when being invoked from the helper from a view
  def get_related_images(work_pid)
#    escaped_pid=work_pid.gsub(/:/, '\\\\\:') # escape the colon found in PIDS for the solr query
    escaped_pid=work_pid.gsub(/:/, '\\\\:') # escape the colon found in PIDS for the solr query
	#puts "QUERY:" + build_related_image_query("imageOf_t:#{escaped_pid}")
	#(solr_response, document_list) = get_search_results(:q=>build_related_image_query("imageOf_t:#{escaped_pid}"))
	(solr_response, document_list) = controller.get_solr_search_results(escaped_pid)
#	(solr_response, document_list) = get_search_results(:q=>build_lucene_query("imageOf_t:#{escaped_pid}"))

#	query="_query_:\"imageOf_t:#{escaped_pid}\"" # search for images that are imageOf this work
#	solr_response = Blacklight.solr.find({:q=>query, :fl=>'id has_model_s title_t'})
#	document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc)}
    return [solr_response, document_list]
  end
  
  #use this method instead of get_related_images when being invoked from the helper from a controller
  def get_related_images_from_controller(work_pid)
	escaped_pid=work_pid.gsub(/:/, '\\\\:') # escape the colon found in PIDS for the solr query
	(solr_response, document_list) = get_solr_search_results(escaped_pid)
    return [solr_response, document_list]
  end

  def get_preferred_work(preferred_work_pid)
	work_af_model = retrieve_af_model('Vrawork')
	fedora_work_object = work_af_model.find(preferred_work_pid) 
	vra_work = fedora_work_object.datastreams_in_memory["VRA"].find_by_terms(:vra_work)
	#vra_work.text

	return vra_work;
  end
  
 def get_preferred_work_object(preferred_work_pid)
	fedora_work_object = Vrawork.find(preferred_work_pid) 
	return fedora_work_object
  end

  def get_longside_max(image_object)
    if image_object.datastreams_in_memory["DELIV-OPS"].find_by_terms(:svg_rect).empty?
		svg_height = Integer(image_object.datastreams_in_memory["DELIV-OPS"].find_by_terms(:svg_image, :svg_height).first.text)
		svg_width = Integer(image_object.datastreams_in_memory["DELIV-OPS"].find_by_terms(:svg_image, :svg_width).first.text)
	else
		svg_height = Integer(image_object.datastreams_in_memory["DELIV-OPS"].find_by_terms(:svg_rect, :svg_rect_height).first.text)
		svg_width = Integer(image_object.datastreams_in_memory["DELIV-OPS"].find_by_terms(:svg_rect, :svg_rect_width).first.text)
	end
	svg_height > svg_width ? svg_height : svg_width
  end

  def build_related_image_query(user_query)
    q = ""
    # start query of with user supplied query term
   #   q << "_query_:\"{!dismax qf=$qf_dismax pf=$pf_dismax}#{user_query}\""
      q << "#{user_query}" # THIS LINE WAS EDITED FROM BUILD_LUCENE_QUUERY METHOD in ACCES_CONTROLS_ENFORCEMENT.rb

    # Append the exclusion of FileAssets
      q << " AND NOT _query_:\"info\\\\:fedora/afmodel\\\\:FileAsset\""

    # Append the query responsible for adding the users discovery level
      permission_types = ["edit","discover","read"]
      field_queries = []
      permission_types.each do |type|
        field_queries << "_query_:\"#{type}_access_group_t:public\""
      end

      unless current_user.nil?
        # for roles
        RoleMapper.roles(current_user.login).each do |role|
          permission_types.each do |type|
            field_queries << "_query_:\"#{type}_access_group_t:#{role}\""
          end
        end
        # for individual person access
        permission_types.each do |type|
          field_queries << "_query_:\"#{type}_access_person_t:#{current_user.login}\""
        end
        if current_user.is_being_superuser?(session)
          permission_types.each do |type|
            field_queries << "_query_:\"#{type}_access_person_t:[* TO *]\""
          end
        end
      end
      q << " AND (#{field_queries.join(" OR ")})"
    return q
  end


  # This method will create a VRA Image object in Fedora.
  # The input is the pid and VRA xml.
  # The output is output indicating a success.
  # If an exception occurs, the controller will catch it.

  def create_vra_image_fedora_object(pid, document)
    
    # create new Fedora object with minted pid
	fedora_object = Multiresimage.new({:pid=>pid})
			
	#set the refid attribute to the new pid
	document.xpath("/vra:vra/vra:image", "vra"=>"http://www.vraweb.org/vracore4.htm").attr("refid", pid)
	        
	#set VRA datastream to the xml document
	fedora_object.datastreams["VRA"].content = document.to_s
		    
	#save Fedora object
	fedora_object.save()
	
	returnXml = "<response><returnCode>Save successful</returnCode><pid>" + pid + "</pid></response>"
	
	return returnXml
	
  end
  
  
  # This method will create a VRA Work object in Fedora.
  # The input is the pid and VRA xml.
  # The output is output indicating a success.
  # If an exception occurs, the controller will catch it.
  
  def create_vra_work_fedora_object(pid, document)

    # create new Fedora object with minted pid
    #ActiveFedora.init()
	fedora_object = Vrawork.new({:pid=>pid})
			
	#set the refid attribute to the new pid
	document.xpath("/vra:vra/vra:work", "vra"=>"http://www.vraweb.org/vracore4.htm").attr("refid", pid)
	        
	#set VRA datastream to the xml document
	fedora_object.datastreams["VRA"].content = document.to_s
		    
	#save Fedora object
	fedora_object.save()
	
	returnXml = "<response><returnCode>Save successful</returnCode><pid>" + pid + "</pid></response>"
	
	return returnXml
    
  end
  
  
  # This method will add a datastream to an object in Fedora.
  # The input is the pid and the datastream's xml, name and label.
  # The output is output indicating a success.
  # If an exception occurs, the controller will catch it.
  
  def update_fedora_object(pid, xml, ds_name, ds_label)
    
    #testing - bogus pid
      #pid = pid + "abc"
    #
    
    #load Fedora object
    #ActiveFedora.init()
    fedora_object = ActiveFedora::Base.load_instance(pid)
  
    #set datastream to xml from the request
    
    #if datastream doesn't already exist, add_datastream
    #if (fedora_object.datastreams[ds_name].nil?)
      new_ds = ActiveFedora::Datastream.new(:dsID=>ds_name, :dsLabel=>ds_label)
      fedora_object.add_datastream(new_ds)
    #end
    
    #debugger
    fedora_object.datastreams[ds_name].content = xml
  
    #save Fedora object
    #debugger
    fedora_object.save()
	
    #update the solr index
    #debugger
    if (ds_name=="VRA")
      fedora_object.update_index()
    end
    
    returnXml = "<response><returnCode>Update successful</returnCode><pid>" + pid + "</pid></response>"
    
    return returnXml
    
  end
  
  def add_external_ds(pid, ds_name, ds_label, ds_location, mime_type)
    
    #testing - bogus pid
      #pid = pid + "abc"
    #
    
    #load Fedora object
    #ActiveFedora.init()
    fedora_object = ActiveFedora::Base.load_instance(pid)
    #set datastream to xml from the request
    
    #if datastream doesn't already exist, add_datastream
    if (fedora_object.datastreams[ds_name].nil?)
      new_ds = ActiveFedora::Datastream.new(:dsID=>ds_name, :dsLabel=>ds_label, :controlGroup=>"E", :dsLocation=>ds_location, :mimeType=>mime_type)
      fedora_object.add_datastream(new_ds)
    end
  
    #save Fedora object
    fedora_object.save()
    
    #update the solr index
    #fedora_object.update_index()

    returnXml = "<response><returnCode>Update successful</returnCode><pid>" + pid + "</pid></response>"
    return returnXml
    
  end



end
