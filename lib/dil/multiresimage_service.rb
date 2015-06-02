require 'dil/pid_minter'

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
      if params[:path] && params[:xml] && params[:accession_nbr]
        begin
          raise "An accession number is required" if params[:accession_nbr].blank?
          raise "Existing image found with this accession number" if existing_image?( params[:accession_nbr] )
          i = Multiresimage.new(pid: mint_pid("dil"), vra_xml: params[:xml], from_menu: true)
          i.save

          i.create_archv_techmd_datastream( params[:path] )
          i.create_archv_exif_datastream( params[:path] )
          i.create_deliv_techmd_datastream( params[:path] )
          ImageMover.delay.move_jp2_to_ansel(i.jp2_img_name, i.jp2_img_path)
          i.create_deliv_ops_datastream
          i.create_deliv_img_datastream
          i.create_archv_img_datastream
          ImageMover.delay.move_tiff_to_repo( i.tiff_img_name, params[ :path ])
          i.edit_groups = [ 'registered' ]
          i.save!

          j = Multiresimage.find( i.pid )
          j.save!


          returnXml = "<response><returnCode>Publish successful</returnCode><pid>#{i.pid}</pid></response>"
        rescue StandardError => msg
          # puts msg.backtrace.join("\n")
          returnXml = "<response><returnCode>Error</returnCode><description>#{msg}</description></response>"
          # Should we wrap everything in a transaction? Or try to delete the fedora object if the creation fails?
          # Delete the work and image if creation fails
          if i
            logger.debug "Deleting work and image..."
            i.vraworks.first.delete if i.vraworks.first
            i.delete
          end
          logger.debug returnXml
        end
      else
        returnXml = "<response><returnCode>Error</returnCode><description>menu_publish requires both image path and VRA xml.</description></response>"
      end
      respond_to do |format|
        format.xml {render :layout => false, :xml => returnXml}
      end
    end

    def find_pid(params, document, vra_type)
      if params[:pid].present?
        pid = params[:pid]
      else
        pid = document.xpath("/vra:vra/vra:#{vra_type}/@vra:refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
        if !pid.present?
          pid = document.xpath("/vra:vra/vra:#{vra_type}/@refid", "vra"=>"http://www.vraweb.org/vracore4.htm").text
        end
      end
      pid
    end

    def create_update_fedora_object

      #check for pid, call create if not, call update if so
      xml = params[:xml].present? ? params[:xml] : request.body.read 

      vra_type = ""
      #there must be a better way than assigning moronically
      if xml.present?
        #load xml into Nokogiri XML document
        document = Nokogiri::XML(xml)
        if document.xpath("/vra:vra/vra:work").present?
          vra_type = "work"
        elsif document.xpath("/vra:vra/vra:image").present?
          vra_type = "image"
        end
      else
        raise "No xml present." #error
      end

      pid = find_pid(params, document, vra_type)
      if pid.nil? #will return nil if not found                " 
        create_fedora_object(vra_type, document, params[:collection])
      else 
        update_fedora(pid, xml, vra_type) 
        head 200   
      end
    end 

    #just thinking, here. can you have a rel_pid without a pid?
    def create_fedora_object(vra_type, document, collection)
      rel_pid = params[:rel_pid]
      if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")
        pid = mint_pid()
        if vra_type == "image"
          #create Fedora object for VRA Image, calls method in helper
          returnXml = create_vra_image_fedora_object(pid, rel_pid, document, collection)
        elsif vra_type == "work"
          #create Fedora object for VRA Work, calls method in helper
          returnXml = create_vra_work_fedora_object(pid, rel_pid, document)
        end
      end
    end

    #expect pid, so either have it or get it from xml
    def update_fedora(pid, document, vra_type)
      begin
        #if request is coming from these IP's, all other ip's will return with the 403 error xml)
        if request.remote_ip.present? and (request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "129.105.203.30" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.238.233")  
          #always assumes a rel_pid exists??? weird but true
           #update_fedora_object(pid, xml, ds_name, ds_label, mime_type)


          # need a way to skip validation for display elements 
          returnXml = update_fedora_object(pid, document, "VRA", "VRA", "text/xml")
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        logger.error("ActiveFedora::ObjectNotFoundError:" + e.message)
        returnXml = "<response><returnCode>Error: An object with that pid was not found in the repository.</returnCode><pid>" + pid + "</pid></response>"
      rescue Exception => e
        logger.error("Exception:   " + e.message)
        returnXml = "<response><returnCode>Error: The object was not saved.</returnCode><pid>" + pid + "</pid></response>"    
      end
    end

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
          #motherfucker. assuming it's under the body.


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

    def existing_image?(accession_nbr)
      if accession_nbr.present?
        logger.info "Checking for existing image..."
        ActiveFedora::SolrService.query("location_display_tesim:\"*Accession:#{accession_nbr}*\" OR location_display_tesim:\"*Voyager:#{accession_nbr}*\"").any?
      end
    end

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

      # Set up default institutional collection pid as being "Digital Image Library"
      institutional_collection_pid = DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]

      # if this is part of an institutional collection, add that relationship
      if collection.present? and DIL_CONFIG["institutional_collection"][collection]
          institutional_collection_pid = DIL_CONFIG["institutional_collection"][collection]["pid"]
      end

      fedora_object.add_relationship(:is_governed_by, "info:fedora/" + institutional_collection_pid)

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
      puts "did we save?? #{pid}"
      logger.debug("created work")

      "<response><returnCode>Save successful</returnCode><pid>" + pid + "</pid></response>"
    end





    # This method will add a datastream to an object in Fedora.
    # The input is the pid and the datastream's xml, name and label.
    # The output is output indicating a success.
    # If an exception occurs, the controller will catch it.

    def update_fedora_object(pid, xml, ds_name, ds_label, mime_type)

      fedora_object = ActiveFedora::Base.find(pid, :cast=>true)
      puts "ok fedora obj #{fedora_object}"
      fedora_object.send(ds_name).content = xml
      fedora_object.send(ds_name).dsLabel = ds_label
      fedora_object.send(ds_name).mimeType = mime_type
      begin
        fedora_object.save()
      rescue StandardError => msg
        puts "Wronged! #{msg}"
      end
      returnXml = "<response><returnCode>Update successful</returnCode><pid>" + pid + "</pid></response>"

      puts "hello???? #{returnXml}"

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
