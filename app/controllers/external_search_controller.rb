##
## This class' index method is a web service that the VRA Editor (or any external app) can call
## to perform a search the same way Hydra does.  It extends CatalogController because it needs to 
## do the search the same way that Blacklight does, but it needs to return the data differently (the solr response as xml).
## This response looks different that querying solr directly.  By letting this service handle the search, this guarantees
## that the VRA Editor search is the same search as Hydra.  We don't have to make changes in both when we change how the 
## search works.
##

class ExternalSearchController < CatalogController
  
  respond_to :xml
  
	def set_format
	  request.format = 'xml'
	end
  
    ## This method is a web service will do a search the same way Blacklight does.
    ## Because Blacklight relies on current_user to build the permissions in the solr query, this
    ## services will login as a user meant to only be used by this service.
    ## The URL to call this service is http://www.example.com:3000/search/search_hydra.xml
    ## The params are: q (for the seach term), sort (for the sort field), per_page (how many results per page), page (page number)
    def index
      begin #for exception handling
        
        #default return xml
        returnXml = "<response><returnCode>403</returnCode></response>"
        
        # only requests from these IP addresses are allowed
	    if !request.remote_ip.nil? and !request.remote_ip.empty? and (request.remote_ip == "129.105.203.30" or request.remote_ip == "129.105.203.122" or request.remote_ip == "129.105.203.236" or request.remote_ip == "127.0.0.1" or request.remote_ip == "129.105.19.60" or request.remote_ip == "129.105.19.59" or request.remote_ip == "129.105.238.233")
	    
	      if !params[:q].nil? and !params[:q].empty?
		    #archivist1 sign in
		    @user = User.find(1)
		    sign_in @user
		  
		    # query solr
		    (@response, @document_list) = get_search_results
		  
		    @filters = params[:f] || []
		    search_session[:total] = @response.total unless @response.nil?
		  
		    #get the xml from the @response to return
		    returnXml = @response.to_xml
		  else
		    returnXml = "<response><returnCode>Error</returnCode><pid/></response>"
		  end
		end #end request_ip if
        
        rescue Exception
          #error xml
          returnXml = "<response><returnCode>Error</returnCode></response>"
      
        ensure #this will get called even if an exception was raised
          #logout
          sign_out @user
      
          #respond to request with returnXml
          respond_with returnXml do |format|
            format.xml {render :layout => false, :xml => returnXml}
          end  
      
       end #end exception handling
   end #end method
end
