class UploadsController < ApplicationController

  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
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
  def create
  
    titleSet_display = current_user.uid + " " + params[:files][0].original_filename
    
    # create the Multiresimage
    @image = Multiresimage.create()
    @image.attach_file(params[:files])
    @image.apply_depositor_metadata(current_user.uid)
    @image.titleSet_display = titleSet_display
    
    @work = Vrawork.create()
    
    @image.add_relationship("is_image_of", "info:fedora/" + @work.pid)
   
    @image.save!
    
    # create the Vrawork
    #@work = Vrawork.create()
    @work.apply_depositor_metadata(current_user.uid)
    @work.titleSet_display = titleSet_display
    @work.datastreams["properties"].delete
    @work.add_relationship("has_image", "info:fedora/" + @image.pid)
    
    #need to save the object before updating it's vra xml
    @work.save!
    
    #update the Vrawork's VRA xml
    #note: the xml_template creates the VRA xml for a VRA image.  Update the vra:image tags to vra:work
    @work.update_vra_work_tag
    
    #update the refid field in the vra xml
    @image.update_ref_id(@image.pid)
    @work.update_ref_id(@work.pid)
    
    #update the relation set in the vra xml for the image and work
    @image.update_relation_set(@work.pid)
    @work.update_relation_set(@image.pid)
    
    UploadFile.create(:user=>current_user, :pid=>@image.pid)
    respond_to do |format|
      format.json {  
        render :json => [@image.to_jq_upload].to_json			
      }
    end

  end

  def enqueue
    
    current_user.upload_files.each do |file|
      #create file on server from Fedora object datastream
      new_filepath="/usr/local/rails_uploaded_images/" + file.pid.gsub(":","") + ".jpg"
      
      Net::HTTP.start("127.0.0.1", 8983) { |http|
        resp = http.get("/fedora/objects/" + file.pid + "/datastreams/raw/content")
        logger.debug("response:" + resp.to_s) 
        open(new_filepath ,"wb") { |new_file|
          new_file.write(resp.body)
        }
      }
      
      FileUtils.chmod(0755, new_filepath)
      
      @image_processing_request = ImageProcessingRequest.create!(:status => 'NEW', :pid=>file.pid, :email => 'm-stroming@northwestern.edu')
      #@image_processing_request.enqueue
      
      # call CGI script with file location (path, name and id)
      # CGI on gandalf will pull file from shirley
      cgi_url = "http://gandalf.library.northwestern.edu/cgi-bin/hydra/hydra-jms.cgi?image_path=" + new_filepath + "&request_id=" + @image_processing_request.id().to_s
	  logger.debug("cgi url: " + cgi_url)
	  # response will be status of script that puts JMS message in queue
	  logger.debug("Before CGI call")
	  cgi_response = Net::HTTP.get_response(URI.parse(cgi_url)).body
	  logger.debug("After CGI call")
	  logger.debug("response:" + cgi_response)
	 
	  #cgi_response = nil
	  if(!cgi_response.nil?)
	   status = "JMS" + cgi_response
	   logger.debug("Update status to: " + status)
	   #update status column in table
	   @image_processing_request.update_attributes(:status=>status)
	  else
       logger.debug("cgi_response is null")
       #update_status
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
