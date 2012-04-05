class ImageProcessingRequest < ActiveRecord::Base
  # include Hydra::AssetsControllerHelper
  # include Hydra::FileAssetsHelper  
  # include Hydra::RepositoryController  
  # include Blacklight::SolrHelper
  
  require "net/http"
  require "uri"

  validates :status, :presence => true
  validates :email, :presence => true
  validates :pid, :presence => true


  def enqueue

puts "finding: #{pid}"
    image = Multiresimage.find(pid)
    new_filepath = image.write_out_raw
      
    # TODO Can we replace the cgi-bin with stomp?
    # call CGI script with file location (path, name and id)
    # CGI on msg server will pull file from app server
    cgi_url = "http://www.example.com/cgi-bin/hydra/hydra-jms.cgi?image_path=" + new_filepath + "&request_id=#{id}"
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
      update_attribute(:status, status)
    else
      logger.debug("cgi_response is null")
      #update_status
    end
  end
  
  def self.update_status(id, status, imageWidth, imageHeight, imagePath)
    logger.debug("Entering update_status")
    
    logger.debug("Retrieve af model")
    af_model = retrieve_af_model('Multiresimage')
    logger.debug("Create new image")
    new_image = af_model.new
    logger.debug("Apply depositor")
    apply_depositor_metadata(new_image)
    logger.debug("Set collection type")
    set_collection_type(new_image, 'Multiresimage')

    # Get  SVG datastream
    logger.debug("Get svg datastream")
    new_svg_ds = new_image.datastreams_in_memory["DELIV-OPS"] 
    logger.debug("Add image params")
    new_svg_ds.add_image_parameters(imagePath,imageWidth,imageHeight)
	
    # Add image and VRA behavior via their cmodels
    logger.debug("Add VRACModel relationship")
    new_image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
    logger.debug("Add imageCModel relationship")
    new_image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
    logger.debug("Save new image")
    new_image.save()
     
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
    image_processing_request = self.find(id)
    if !image_processing_request.nil?
      status = "VALIDATED" + status
      logger.debug("image_processing_request is not null")
      self.update(id, {:status=>status, :image_pid=>"pid"})
    end
    
  end

end
