class UploadsController < ApplicationController

  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include Blacklight::SolrHelper
 
  skip_before_filter :verify_authenticity_token, :only=>[:update_status]
  before_filter :authenticate_user!, :except=>[:update_status]
  #TODO ensure that only our script is calling update_status

  def index
    respond_to do |format|
      format.json {
        #TODO find_by_solr could be faster 
        @multiresimages = current_user.upload_files.map do |file|
          begin
            Multiresimage.find(file.pid)
          rescue ActiveFedora::ObjectNotFoundError
          end
        end.compact
        render :json=>@multiresimages.map(&:to_jq_upload)
      }
      format.html
    end
  end

  def create
    @image = Multiresimage.create()
    @image.attach_file(params[:files])
    @image.apply_depositor_metadata(current_user.uid)
    @image.save!
    UploadFile.create(:user=>current_user, :pid=>@image.pid)
    respond_to do |format|
      format.json {  
        render :json => [@image.to_jq_upload].to_json			
      }
    end

  end

  def enqueue
    current_user.upload_files.each do |file|
      @image_processing_request = ImageProcessingRequest.create!(:status => 'NEW', :pid=>file.pid, :email => 'm-stroming@northwestern.edu')
      @image_processing_request.enqueue
    end
    current_user.upload_files.delete_all
      
    redirect_to catalog_index_path, :notice=>'Your files are now being processed'
  end
  
  def update_status
    logger.debug("Entering update_status")
    
    logger.debug("Retrieve af model")
    image_processing_request = ImageProcessingRequest.find(params[:request_id])

    image = Multiresimage.find(image_processing_request.pid)
    # Get  SVG datastream
    logger.debug("Get svg datastream")
    new_svg_ds = image.datastreams["DELIV-OPS"] 

    logger.debug("Add image params")
    new_svg_ds.add_image_parameters(params[:image_path], params[:width], params[:height])
    #new_svg_ds.add_image_parameters("test", "100", "100")
    
    # Add image and VRA behavior via their cmodels
    logger.debug("Add VRACModel relationship")
    image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
    logger.debug("Add imageCModel relationship")
    image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
    logger.debug("Save new image")
    image.save()
    logger.debug("Image saved")
     
    image_processing_request.update_attribute(:status, "VALIDATED" + params[:status])
    
    render :nothing => true
  end


  
end
