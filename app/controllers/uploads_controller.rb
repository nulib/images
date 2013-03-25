class UploadsController < ApplicationController

  include Hydra::Controller::UploadBehavior  
  include Hydra::Controller::RepositoryControllerBehavior  
  include Blacklight::SolrHelper
  include DIL::PidMinter
  
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
 
  #filename the user gave the file
  #filename = params[:files][0].original_filename
  
  # Sanitize the filename - upload security - Code from Rails security guide
  params[:files][0].original_filename.strip.tap do |name|
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    # get only the filename, not the whole path
    name.sub! /\A.*(\\|\/)/, ''
    # Finally, replace all non alphanumeric, underscore
    # or periods with underscore
    name.gsub! /[^\w\.\-]/, '_'
   end
   
    
    titleSet_display = current_user.user_key + " " + params[:files][0].original_filename
    error = false
    
    #Create ClamAV instance for virus scanning
    clam = ClamAV.instance
    
    #Load ClamAV definitions
    clam.loaddb
    
    #Scan file (will return fixnum if ok, string with virus name if not ok)
    if params[:files][0].is_a? Tempfile
      logger.debug("TEMPFILE: #{params[:files][0].tempfile.path}")
      scan_result = clam.scanfile(params[:files][0].tempfile.path)
    else
      logger.debug("FILE: #{params[:files][0].path}")
      scan_result = clam.scanfile(params[:files][0].path)
    end
    
    if (scan_result.is_a? Fixnum)
      # create the Multiresimage
      
      edit_users_array = DIL_CONFIG['admin_staff'] | Array.new([current_user.user_key])
      
      @image = Multiresimage.new(:pid=>mint_pid("dil-local"))
      logger.debug("FILES:#{params[:files]}")
      @image.attach_file(params[:files])
      @image.apply_depositor_metadata(current_user.user_key)
      @image.edit_users = edit_users_array
      @image.titleSet_display = titleSet_display
      @image.save!
    
      @work = Vrawork.new(:pid=>mint_pid("dil-local"))
    
      @image.add_relationship(:is_image_of, "info:fedora/" + @work.pid)
      @work.apply_depositor_metadata(current_user.user_key)
      @work.edit_users = edit_users_array
      @work.datastreams["properties"].delete
      @work.add_relationship(:has_image, "info:fedora/" + @image.pid)
    
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
      
      #add image to Uploads collection
      personal_collection = current_user.get_uploads_collection
      DILCollection.add_image_to_personal_collection(personal_collection, DIL_CONFIG['dil_uploads_collection'], @image, current_user.user_key)
    
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
    vraSetArray = ["agent", "title", "culturalContext", "date", "subject", "location", "source", "technique", "material", "measurements", "stylePeriod", "inscription", "description", "worktype"]
    theItems = Hash.new
    vraSetArray.each do |itm|

      if(params.has_key?("#{itm}Set_display"))
        theItems[itm] ||= params["#{itm}Set_display"]
      end
    end

    current_user.upload_files.each do |file|
      @image_processing_request = ImageProcessingRequest.create!(:status => 'NEW', :pid=>file.pid, :email => 'm-stroming@northwestern.edu')
      @image_processing_request.enqueue

      # This populates the Multiresimages with the batch params
      aCheck = false
      img = Multiresimage.find(file.pid)

      vraSetArray.each do |itm|
        if(not theItems[itm].blank?)
          img.send("#{itm}Set_display=", theItems[itm])
          aCheck = true
        end
      end unless img == nil

      if(aCheck)
        img.save unless img == nil
      end
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
