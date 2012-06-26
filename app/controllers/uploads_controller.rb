class UploadsController < ApplicationController

  include Hydra::AssetsControllerHelper
  include Hydra::Controller::UploadBehavior  
  include Hydra::Controller::RepositoryControllerBehavior  
  include Blacklight::SolrHelper
  
  require 'net/http'
 
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

  # After the image is uploaded, create Multiresimage and Vrawork Fedora objects
  # Called from Jquery uploader, ajax call, respond with JSON
  def create
    logger.debug("TEST_1")
    titleSet_display = current_user.user_key + " " + params[:files][0].original_filename
    logger.debug("TEST_2")
    error = false
    
    #Create ClamAV instance for virus scanning
    clam = ClamAV.instance
    
    #Load ClamAV definitions
    clam.loaddb
    
    #Scan file (will return fixnum if ok, string with virus name if not ok)
    if params[:files][0].is_a? Tempfile
      scan_result = clam.scanfile(params[:files][0].tempfile.path)
    else
      scan_result = clam.scanfile(params[:files][0].path)
    end
    
    if (scan_result.is_a? Fixnum)
      # create the Multiresimage
      @image = Multiresimage.create()
      @image.attach_file(params[:files])
      @image.apply_depositor_metadata(current_user.user_key)
      @image.titleSet_display = titleSet_display
      @image.save!
    
      @work = Vrawork.create()
    
      @image.add_relationship(:is_image_of, "info:fedora/" + @work.pid)
    
      @work.apply_depositor_metadata(current_user.user_key)
    
      @work.datastreams["properties"].delete
      @work.add_relationship(:has_image, "info:fedora/" + @image.pid)
    
      #need to save the object before updating it's vra xml
      @work.save!
    
      #update the Vrawork's VRA xml
      #note: the xml_template creates the VRA xml for a VRA image.  Update the vra:image tags to vra:work
      @work.update_vra_work_tag
    
      @work.titleSet_display_work = titleSet_display
    
      #update the refid field in the vra xml
      @image.update_ref_id(@image.pid)
      @work.update_ref_id(@work.pid)
    
      #update the relation set in the vra xml for the image and work
      @image.update_relation_set(@work.pid)
      @work.update_relation_set(@image.pid)
    
      @work.save!
      @image.save!
    
      UploadFile.create(:user=>current_user, :pid=>@image.pid)
      
    else
      error = true
      logger.error("VIRUS_DETECTED: #{scan_result} : #{params[:files][0].tempfile.path}")
      
      #delete file from file system
      File.delete params[:files][0].tempfile.path
    end
    
    respond_to do |format|
       if !error
        format.json {  
          render :json => [@image.to_jq_upload].to_json			
        }
        #custom error message, responds to AJAX call 
        else
          format.json {  
            render :json => "[{\"error\":\"VIRUS DETECTED\"}]"
        }
        end
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
    
    logger.debug("Removing raw datastream")
    image.datastreams["raw"].delete
    
    logger.debug("Removing properties datastream")
    image.datastreams["properties"].delete
    
    logger.debug("Save new image")
    image.save()
    logger.debug("Image saved")
     
    image_processing_request.update_attribute(:status, "VALIDATED" + params[:status])
    
    render :nothing => true
  end


  
end
