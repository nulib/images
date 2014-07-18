module DIL
  module MultiresimageService
    # include Hydra::AssetsControllerHelper
    # include Blacklight::SolrHelper
    include DIL::PidMinter


    # This method/web service is called from other applications (Orbeon VRA Editor, migration scripts).
    # The URL to call this method/web service is http://localhost:3000/multiresimages/create_update_fedora_object.xml
    # It's expecting a pid param in the URL (it will check the VRA xml in the xml), as well as VRA xml in the POST request.
    # This method will create or update a Fedora object using the VRA xml that's included in the POST request



    def menu_publish
      logger.debug "menu_publish api was just called"

      # Set the image location to empty string if no location was passed in the request
      img_location = params[:location] == nil ? "" : params[:location]

      logger.debug "image location: #{img_location}"

      begin
        i = Multiresimage.new(pid: mint_pid("dil"), vra_xml: params[:xml], from_menu: true)
        i.save
        returnXml = "<response><returnCode>Publish successful</returnCode><pid>#{i.pid}</pid></response>"
      rescue StandardError => msg
        returnXml = "<response><returnCode>Error</returnCode><description>#{msg}</description></response>"
      end
      respond_to do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end
    end


    def create_update_fedora_object
      begin #for exception handling

        #default return xml
        returnXml = "<response><returnCode>403</returnCode></response>"
        #if request is coming from these IP's, all other ip's will return with the 403 error xml)

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")
  		  #update returnXml (this is the error xml, will be updated if success)
  			returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid/></response>"

  			#read in the xml from the POST request
  			xml = request.body.read

  			#make sure xml is not nil and not empty
  			if xml.present?
  			  #load xml into Nokogiri XML document
  			  document = Nokogiri::XML(xml)
  			  vra_type = ""
  			  pid = ""
  			  rel_pid = ""

  			  #pid might be a query param
  			  #debugger
  			  if params[:pid].present?
    				pid = params[:pid]
    				logger.debug("PID:" + pid)
  			  end

  			  #rel_pid might be a query param
  			  if params[:rel_pid].present?
    				rel_pid = params[:rel_pid]
    				logger.debug("RELATED_PID:" + rel_pid)
  			  end

  			  #determine if xml represents VRA work or VRA image by running xpath query and checking the result
  			  if document.xpath("/vra:vra/vra:work").present?
    				vra_type = "work"
    				logger.debug("WORK")
    				#attempt to extract the pid by running xpath query
    				if !pid.present?
    				  pid = document.xpath("/vra:vra/vra:work/@vra:refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
    				  if !pid.present?
    					  pid = document.xpath("/vra:vra/vra:work/@refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
    				  end
  				  end
  			  elsif document.xpath("/vra:vra/vra:image").present?
    				#debugger
    				vra_type = "image"
    				logger.debug("IMAGE")
    				#attempt to extract the pid by running xpath query
    				if !pid.present?
    				  pid = document.xpath("/vra:vra/vra:image/@vra:refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
    				  if !pid.present?
    					  pid = document.xpath("/vra:vra/vra:image/@refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
  				    end
				    end
			    end

  			  #if no pid was in the xml, then create a new Fedora object
  			  if !pid.present?
  				  #mint a pid
  				  pid = mint_pid()
  				  #if pid was minted successfully
  				  if pid.present?
  				    if vra_type == "image"
  					    #create Fedora object for VRA Image, calls method in helper
  					    returnXml = create_vra_image_fedora_object(pid, rel_pid, document, params[:collection])
  				    elsif vra_type == "work"
  					    #create Fedora object for VRA Work, calls method in helper
  					    returnXml = create_vra_work_fedora_object(pid, rel_pid, document)
  				    end
				    end


			      #pid was in xml so update the existing Fedora object if the object exists, or create the object if it doesn't exist
			      #(a pid might have been minted before this web service was called)
			    else
  				  #begin
  				  logger.debug("FIND IN AF")
  				  if (ActiveFedora::Base.exists?(pid))
  				    #object already exists, update the object
  				    returnXml = update_fedora_object(pid, xml, "VRA", "VRA", "text/xml")
  				  else
  				    #if object doesn't exist in Fedora, create the object, then update
  			        #create the object
  				    if vra_type == "image"
  					    returnXml = create_vra_image_fedora_object(pid, rel_pid, document, params[:collection])
  				    elsif vra_type == "work"
  					    returnXml = create_vra_work_fedora_object(pid, rel_pid, document)
  				    end
  				  end
  			    #else
  				    #returnXml = update_fedora_object(pid, xml, "VRA", "VRA")
  				  #end

    				#if a work, get a list of it's related images, and re-index those images (because work info
    				#is indexed with the image, need to update the image index after the work index has been updated)
    				#if vra_type == "work"
    				 #(solr_response, document_list) = get_related_images_from_controller(pid)
    				  #document_list.each { |i|
    					#load fedora object for the image
    					#fedora_object = ActiveFedora::Base.find(i.id, :cast=>true)
    					#update it's solr index
    					#fedora_object.update_index()
    				 # }
    				#end
    			end #end pid if-else
	      end #end xml_params if
      end #end request_ip if
      rescue ActiveFedora::ObjectNotFoundError => e
        #error xml
        logger.error("ActiveFedora::ObjectNotFoundError:" + e.message)
        returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"
      rescue Exception => e
        #error xml
        logger.error("Exception:" + e.message)
        #logger.debug("PID:" + pid)
        returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid>" + pid + "</pid></response>"
      ensure #this will get called even if an exception was raised
        #respond to request with returnXml
        respond_with returnXml do |format|
          format.xml {render :layout => false, :xml => returnXml}
        end
      end # end exception handling
    end #end method


    # This method/web service is called from other applications (migration scripts).
    # The URL to call this method/web service is http://localhost:3000/multiresimages/add_datastream.xml
    # It's expecting the following params in the URL: pid, ds_name, ds_label.  Also expecting xml in the POST request
    # This method will add a datastream to an existing Fedora object using the xml that's included in the POST request

    def add_datastream

      begin #for exception handling
        #default return xml
        returnXml = "<response><returnCode>403</returnCode></response>"

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")
		      #update returnXml (this is the error xml, will be updated if success)
          returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid/></response>"
          #read in the xml from the POST request
          xml = request.body.read
          #make sure xml, pid, and datstream name and datastream label are not nil and not empty
          if xml.present? and params[:pid].present? and params[:ds_name].present? and params[:ds_label].present?
            #calls method in helper
            returnXml = update_fedora_object(params[:pid], xml, params[:ds_name], params[:ds_label], params[:mime_type])
          end #end xml_params if
        end #end request_ip if

      rescue ActiveFedora::ObjectNotFoundError => e
        #error xml
        logger.error("ActiveFedora::ObjectNotFoundError:" + e.message)
        returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + params[:pid] + "</pid></response>"
      rescue Exception => e
        #error xml
        logger.error("Exception:" + e.message)
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

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")
			    #update returnXml (this is the error xml, will be updated if success)
			    returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid/></response>"

    			#read in the xml from the POST request
    			#xml = request.body.read
    			#make sure pid, datstream name, datastream label and datastream location are not nil and not empty
    			if params[:pid].present? and params[:ds_name].present? and params[:ds_label].present? and params[:ds_location].present? and params[:mime_type].present?
    				#calls method in helper
    				returnXml = add_external_ds(params[:pid], params[:ds_name], params[:ds_label], params[:ds_location], params[:mime_type])
    			end #end xml_params if
        end #end request_ip if
      rescue ActiveFedora::ObjectNotFoundError => e
        #error xml
        logger.error("ActiveFedora::ObjectNotFoundError" + e.message)
        returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"

      rescue Exception => e
        #error xml
        logger.error("Exception:" + e.message)
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

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")

          #update returnXml (this is the error xml, will be updated if success)
          returnXml = "<response><returnCode>Error: The object was not deleted.</returnCode><pid/></response>"

    		  if params[:pid].present?
      			fedora_object = ActiveFedora::Base.find(params[:pid], :cast=>true)
      			fedora_object.delete
      		  returnXml = "<response><returnCode>Delete successful</returnCode><pid>" + params[:pid] + "</pid></response>"
    			end

        end #end request_ip if

      rescue ActiveFedora::ObjectNotFoundError => e
        #error xml
        logger.error("ActiveFedora::ObjectNotFoundError:" + e.message)
        returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"

      rescue Exception => e
        #error xml
        logger.error("Exception:" + e.message)
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

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")

    			#update returnXml (this is the error xml, will be updated if success)
    			returnXml = "<response><returnCode>Error: The object was not cloned.</returnCode><pid/></response>"

    			if params[:pid].present?

    				pid = params[:pid]

    				orig_fedora_object = ActiveFedora::Base.find(pid, :cast=>true)

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

      rescue ActiveFedora::ObjectNotFoundError => e
        #error xml
        logger.error("ActiveFedora::ObjectNotFoundError:" + e.message)
        returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"

      rescue Exception => e
        #error xml
        logger.error("Exception:" + e.message)
        returnXml = "<response><returnCode>Error: The object was not cloned.</returnCode><pid>" + pid + "</pid></response>"

      ensure #this will get called even if an exception was raised
        #respond to request with returnXml
        respond_with returnXml do |format|
          format.xml {render :layout => false, :xml => returnXml}
        end
      end

    end #end method

    # This web service will return the pids of the objects for an accession number (not including detail image objects).
    # The URL to call this method/web service is https://localhost:3000/multiresimages/get_pid_from_accession_number.xml
    # It's expecting the following params in the URL: accessionNbr
    def get_pids_from_accession_number

      begin #for exception handling
        #default return xml

        return_xml = "<response><returnCode>403</returnCode></response>"

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")

    			#update returnXml (this is the error xml, will be updated if success)
    			return_xml = "<response><returnCode>Error: Could not find object. Accession Number: #{params[:accessionNbr]}</returnCode><pid/></response>"

			    if params[:accessionNbr].present?

    			  accession_nbr = params[:accessionNbr]

    			  # Query Solr to find Multiresimage object that has the accession nbr
    			  pids = ActiveFedora::SolrService.query("search_field_tesim:\"Voyager:#{accession_nbr}\" AND object_type_facet:Multiresimage AND -is_crop_of_ssim:[* TO *]")

    			  #if one image object found
    			  if (pids.present? and pids.size == 1)
              #get pid from Solr result
              if (pids[0]["id"].present?)
                image_pid = pids[0]["id"]
                return_xml = "<pids><image_pid>#{image_pid}</image_pid>"
                image = Multiresimage.find(image_pid)

                #get the related work's pid
    			      #if image has work, get pid
    			      if (image.vraworks.present?)
    			        work_pid = image.vraworks[0].pid
    			      elsif (image.VRA.relationSet_ref.imageOf.relation_relids.first.present?)
    			        work_pid = image.VRA.relationSet_ref.imageOf.relation_relids.first
    			      end

    			      if (work_pid.present?)
    			        return_xml << "<work_pid>#{work_pid}</work_pid>"
    			      end

    			      return_xml << "</pids>"
              end
            # if more than one object found
            elsif (pids.present? and pids.size > 1)
              return_xml = "<response><returnCode>Error: More than one object found. Accession Number: #{accession_nbr}</returnCode><pid/></response>"
			      end
			    end
        end #end request_ip if

      rescue Exception => e
        #error xml
        logger.debug("Exception:" + e.message)
        return_xml = "<response><returnCode>Error: Could not find object.</returnCode></response>"

      ensure #this will get called even if an exception was raised
        #respond to request with returnXml
        respond_with return_xml do |format|
          format.xml {render :layout => false, :xml => return_xml}
        end
      end

    end #end method



    # This web service will return the nbr of objects (not including detail image objects) found given an accession nbr and title
    # The URL to call this method/web service is https://localhost:3000/multiresimages/get_number_of_objects.xml
    # It's expecting the following params in the URL: accessionNbr, title
    def get_number_of_objects

      begin #for exception handling
        #default return xml

        return_xml = "<response><returnCode>403</returnCode></response>"

        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")

    			#update returnXml (this is the error xml, will be updated if success)
    			return_xml = "<response><returnCode>Error: Could not find object. Accession Number: #{params[:accessionNbr]}</returnCode><pid/></response>"

    			if params[:accessionNbr].present? and params[:title].present?

    			  # Query Solr to find objects that have the accession nbr and title in the search_field_tesim field
    			  pids = ActiveFedora::SolrService.query("search_field_tesim:\"Voyager:#{params[:accessionNbr]}\" AND search_field_tesim:\"#{params[:title]}\" AND -is_crop_of_ssim:[* TO *]")
    			  return_xml = "<numberObjects>#{pids.size}</numberObjects>"

    			else
    			  return_xml = "<response><returnCode>Error: Invalid params</returnCode></response>"
    			end
        end #end request_ip if

      rescue Exception => e
        #error xml
        logger.debug("Exception:" + e.message)
        return_xml = "<response><returnCode>Error: Exception</returnCode></response>"

      ensure #this will get called even if an exception was raised
        #respond to request with returnXml
        respond_with return_xml do |format|
          format.xml {render :layout => false, :xml => return_xml}
        end
      end

    end #end method




    private

    def build_related_image_query(user_query)
      q = "#{user_query}"
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
      q
    end


    #This method calls a method within Blacklight::SolrHelper.  It needs to invoked from a view helper, but the view helper can't invoke it
    #directly.  The view helper (multiresimage_helper) invokes this method, which invokes the get_search_results method in Blacklight::SolrHelper
    def get_solr_search_results(escaped_pid)
      (solr_response, document_list) = get_search_results(:q=>build_related_image_query("imageOf_tesim:#{escaped_pid}"))
      return solr_response, document_list
    end



    #use this method instead of get_related_images when being invoked from the helper from a controller
    def get_related_images_from_controller(work_pid)
      escaped_pid=work_pid.gsub(/:/, '\\\\:') # escape the colon found in PIDS for the solr query
      (solr_response, document_list) = get_solr_search_results(escaped_pid)
      return [solr_response, document_list]
    end




    # This method will create a VRA Image object in Fedora.
    # The input is the pid and VRA xml.
    # The output is output indicating a success.
    # If an exception occurs, the controller will catch it.

    def create_vra_image_fedora_object(pid, rel_pid, document, collection=nil)
      logger.debug("create_image_method")
      # create new Fedora object with minted pid
      fedora_object = Multiresimage.new({:pid=>pid})

      #set the refid attribute to the new pid
      document.xpath("/vra:vra/vra:image", "vra"=>"http://www.vraweb.org/vracore4.htm").attr("refid", pid)

      #set VRA datastream to the xml document
      fedora_object.datastreams["VRA"].content = document.to_s

      #set rightsMetadata
      #fedora_object.rightsMetadata
      #fedora_object.datastreams["rightsMetadata"].content = "<rightsMetadata xmlns='http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1' version='0.1'> <copyright> <human></human> <machine> <uvalicense>no</uvalicense> </machine> </copyright> <access type='discover'> <human></human> <machine> <group>public</group> </machine> </access> <access type='read'> <human></human> <machine> <group>public</group> </machine> </access> <access type='edit'> <human></human> <machine></machine> </access> <embargo> <human></human> <machine></machine> </embargo> </rightsMetadata>"

      #todo: make groups be a param to the API
      fedora_object.read_groups = ["registered"]
      #fedora_object.edit_groups = ["registered"]

      #add rels-ext has_image relationship (VRAItem isImageOf VRAWork)
      fedora_object.add_relationship(:is_image_of, "info:fedora/" + rel_pid)

      # if this is part of an institutional collection, add that relationship
      if collection.present?
        # Set up default institutional collection pid as being "Digital Image Library"
        institutional_collection_pid = DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]

        if DIL_CONFIG["institutional_collection"][collection]
          institutional_collection_pid = DIL_CONFIG["institutional_collection"][collection]["pid"]
        end

        fedora_object.add_relationship(:is_governed_by, "info:fedora/" + institutional_collection_pid)
      end

      #add rels-ext CModel relationship
      #fedora_object.add_relationship(:has_model, "info:fedora/inu:VRACModel")

      #save Fedora object
      fedora_object.save
      logger.debug("created image")

      "<response><returnCode>Save successful</returnCode><pid>" + pid + "</pid></response>"
    end





    # This method will create a VRA Work object in Fedora.
    # The input is the pid and VRA xml.
    # The output is output indicating a success.
    # If an exception occurs, the controller will catch it.

    def create_vra_work_fedora_object(pid, rel_pid, document)
      logger.debug("create_work_method")
      # create new Fedora object with minted pid
      #ActiveFedora.init()
      fedora_object = Vrawork.new({:pid=>pid})

      #set the refid attribute to the new pid
      document.xpath("/vra:vra/vra:work", "vra"=>"http://www.vraweb.org/vracore4.htm").attr("refid", pid)

      #set VRA datastream to the xml document
      fedora_object.datastreams["VRA"].content = document.to_s

      #set rightsMetadata
      #fedora_object.rightsMetadata
      #fedora_object.datastreams["rightsMetadata"].content = "<rightsMetadata xmlns='http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1' version='0.1'> <copyright> <human></human> <machine> <uvalicense>no</uvalicense> </machine> </copyright> <access type='discover'> <human></human> <machine> <group>public</group> </machine> </access> <access type='read'> <human></human> <machine> <group>public</group> </machine> </access> <access type='edit'> <human></human> <machine></machine> </access> <embargo> <human></human> <machine></machine> </embargo> </rightsMetadata>"

      #todo: make groups be a param to the API
      fedora_object.read_groups  = ["registered"]
      #fedora_object.edit_groups = ["registered"]

      #add rels-ext has_image relationship (VRAWork hasImage VRAItem)
      fedora_object.add_relationship(:has_image, "info:fedora/" + rel_pid)

      #add rels-ext CModel relationship
      #fedora_object.add_relationship(:has_model, "info:fedora/inu:VRACModel")

      #save Fedora object
      fedora_object.save
      logger.debug("created work")

      "<response><returnCode>Save successful</returnCode><pid>" + pid + "</pid></response>"
    end





    # This method will add a datastream to an object in Fedora.
    # The input is the pid and the datastream's xml, name and label.
    # The output is output indicating a success.
    # If an exception occurs, the controller will catch it.

    def update_fedora_object(pid, xml, ds_name, ds_label, mime_type)

      #load Fedora object
      fedora_object = ActiveFedora::Base.find(pid, :cast=>true)

      #set datastream to xml from the request

      #if datastream doesn't already exist, add_datastream
      #if (fedora_object.datastreams[ds_name].nil?)
        #new_ds = ActiveFedora::Datastream.new(fedora_object, ds_name)
        #fedora_object.add_datastream(new_ds)
      #end

      #create datastream
      #fedora_object.send(ds_name)

      #set datastream content
      #fedora_object.datastreams[ds_name].content = xml

      fedora_object.send(ds_name).content = xml
      fedora_object.send(ds_name).dsLabel = ds_label
      fedora_object.send(ds_name).mimeType = mime_type

      #save Fedora object
      #debugger
      fedora_object.save

      #update the solr index
      #debugger
      #if (ds_name=="VRA")
       # fedora_object.update_index()
      #end

      returnXml = "<response><returnCode>Update successful</returnCode><pid>" + pid + "</pid></response>"

      return returnXml

    end

    def add_external_ds(pid, ds_name, ds_label, ds_location, mime_type)
      #load Fedora object
      fedora_object = ActiveFedora::Base.find(pid, :cast=>true)
      #set datastream to xml from the request

      #if datastream doesn't already exist, add_datastream
      #if (fedora_object.datastreams[ds_name].nil?)
        #needs updated syntax
        #new_ds = ActiveFedora::Datastream.new(:dsID=>ds_name, :dsLabel=>ds_label, :controlGroup=>"E", :dsLocation=>ds_location, :mimeType=>mime_type)
        #fedora_object.add_datastream(new_ds)
        fedora_object.datastreams[ds_name].dsLabel=ds_label
        fedora_object.datastreams[ds_name].dsLocation=ds_location
        fedora_object.datastreams[ds_name].mimeType=mime_type
        fedora_object.datastreams[ds_name].controlGroup='E'
      #end

      #save Fedora object
      fedora_object.save

      "<response><returnCode>Update successful</returnCode><pid>" + pid + "</pid></response>"
    end


  end
end
