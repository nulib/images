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
    image = begin
      Multiresimage.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      update_attribute(:status, "Not found")
      return
    end
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
    end
  end
end
