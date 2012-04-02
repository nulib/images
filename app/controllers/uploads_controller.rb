#require 'mediashelf/active_fedora_helper'

class UploadsController < ApplicationController

  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
 
  skip_before_filter :verify_authenticity_token
  
  before_filter :require_fedora
  before_filter :require_solr
  
  def test
    debugger
    test = "test"
  end
  
  # called from upload form for multiresimage
  def create
    logger.debug("Entering create method")
    logger.debug("Before IPR row created")
    
    if !params[:container_id].nil? && params[:Filedata]
      #logger.debug("current object pid: " + params[:container_id])
      logger.debug("image filename: " + params[:Filedata][0].original_filename)
      logger.debug("temp image path: " + params[:Filedata][0].path)
      
      #rename and move file
      new_filepath = "/usr/local/rails_uploaded_images/"+ params[:Filedata][0].original_filename
      logger.debug("New filepath:" + new_filepath)
      FileUtils.mv(params[:Filedata][0].path, new_filepath)
      FileUtils.chmod(0755, new_filepath)
      
      @image_processing_request = ImageProcessingRequest.new(:status => 'NEW',:image_filename => params[:Filedata][0].original_filename, :email => 'm-stroming@northwestern.edu')
      
       if(@image_processing_request.save())
         logger.debug("Row saved to database")
       else
         logger.debug("Row NOT saved to database")
       end
       
       # call CGI script with file location (path, name and id)
      # CGI on msg server will pull file from app server
      cgi_url = "http://www.example.com/cgi-bin/hydra/hydra-jms.cgi?image_path=" + new_filepath + "&request_id=" + @image_processing_request.id().to_s
	  logger.debug("cgi url: " + cgi_url)
	  # response will be status of script that puts JMS message in queue
	  logger.debug("Before CGI call")
	  cgi_response = Net::HTTP.get_response(URI.parse(cgi_url)).body
	  logger.debug("After CGI call")
	  #logger.debug("response:" + cgi_response)
	 
	  cgi_response = nil
	  if(!cgi_response.nil?)
	   status = "JMS" + cgi_response
	   logger.debug("Update status to: " + status)
	   #update status column in table
	   @image_processing_request.update_attributes(:status=>status)
	  else
       logger.debug("cgi_response is null")
       #update_status
      end
      
     # if current_user.nil?
     # 	logger.debug("current_user is null")
     # end
     
     # Create new image_processing_request row
     #ImageProcessingRequest.new_request('NEW', params[:Filedata].path, params[:Filename], "m-stroming@northwestern.edu")
      
    else
      logger.debug("container_id or Filedata null")
    end
     
     #testing call
     #update_status(1, "OK", 1, 2, "path")
     
     render :nothing => true
     
  end
  
  #def update_status
  #  logger.debug("Calling ImageProcessingRequest.update_status")
   # ImageProcessingRequest.update_status(params[:request_id], params[:status], params[:width], params[:height], params[:image_path])
    
   # render :nothing => true
    #return pid
  #end
  
  def update_status
    logger.debug("Entering update_status")
    
    logger.debug("Retrieve af model")
    #af_model = retrieve_af_model('Multiresimage')
	logger.debug("Create new image")
	new_image = Multiresimage.new()
	logger.debug("Apply depositor")
	new_image.apply_depositor_metadata("archivist1")
	logger.debug("Set collection type")
	set_collection_type(new_image, 'Multiresimage')

	# Get  SVG datastream
	logger.debug("Get svg datastream")
	new_svg_ds = new_image.datastreams["DELIV-OPS"] 
	logger.debug("Add image params")
	new_svg_ds.add_image_parameters(params[:image_path], params[:width], params[:height])
	#new_svg_ds.add_image_parameters("test", "100", "100")
	new_image.save()
	
	# Add image and VRA behavior via their cmodels
	logger.debug("Add VRACModel relationship")
    new_image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
    logger.debug("Add imageCModel relationship")
    new_image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
    logger.debug("Save new image")
	new_image.save()
	logger.debug("Image saved")
     
    #  logger.debug("Creating new fedora object")
    #  af_model = retrieve_af_model("multiresimage")
    #    if af_model
    #      @asset = af_model.new
    #     apply_depositor_metadata(@asset)
    #     set_collection_type(@asset, params[:content_type])
    #     @asset.save
    #     logger.debug("new object pid: " + @asset.pid)
    #   end
    
    # update status in table
    
    #make sure row exists, if so, update
    image_processing_request = ImageProcessingRequest.find(params[:request_id])
    if !image_processing_request.nil?
      status = "VALIDATED" + params[:status]
      logger.debug("status: " + status)
      logger.debug("image_processing_request is not null")
      ImageProcessingRequest.update(params[:request_id], {:status=>status, :image_pid=>new_image.pid()})
    end
    
  #return pid
  
  render :nothing => true
  end
  
  
end
