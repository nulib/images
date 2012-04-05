class UploadsController < ApplicationController

  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include Blacklight::SolrHelper
 
  skip_before_filter :verify_authenticity_token #TODO Bad idea. Just restrict this to the methods that need it (update_status?).
  before_filter :authenticate_user!, :only=>[:index, :create]
  #TODO ensure that only our script is calling update_status

  def index
    respond_to do |format|
      format.json {
        #TODO find_by_solr could be faster 
        @multiresimages = selected_files.map {|pid| Multiresimage.find(pid)}
        render :json=>@multiresimages.map(&:to_jq_upload)
      }
      format.html
    end
  end

  def create
    session[:files] ||= []
    uploaded_io = params[:files].first
    image = Multiresimage.create(params)
    session[:files] << image.pid 
    respond_to do |format|
      format.json {  
        render :json => [image.to_jq_upload].to_json			
      }
    end

  end

  def enqueue
    logger.debug("Entering enqueue method")
    logger.debug("Before IPR row created")
    

    selected_files.each do |pid|
      
      #logger.debug("current object pid: " + params[:container_id])
      logger.debug("image filename: " + params[:Filedata][0].original_filename)
      logger.debug("temp image path: " + params[:Filedata][0].path)
      
      @image_processing_request = ImageProcessingRequest.new(:status => 'NEW', :pid=>pid, :email => 'm-stroming@northwestern.edu')
      
      if(@image_processing_request.save())
        logger.debug("Row saved to database")
      else
        logger.debug("Row NOT saved to database")
      end
       

      @image_processing_request.enqueue
    end
      
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


  private 

  def selected_files
    session[:files] ||= []
  end
  
  
end
