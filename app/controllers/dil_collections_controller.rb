class DilCollectionsController < ApplicationController
  
  include Blacklight::Catalog
  include Blacklight::SolrHelper
  include DIL::PidMinter

  def create
    authorize!(:create, DILCollection)
	  #make sure collection's name isn't a reserved name for Uploads and Details collections
	  if params[:dil_collection][:title].downcase == DIL_CONFIG['dil_uploads_collection'].downcase || params[:dil_collection][:title].downcase == DIL_CONFIG['dil_details_collection'].downcase
	    flash[:alert] = "Cannot use that collection name. That name is reserved."
	  else	
	    edit_users_array = DIL_CONFIG['admin_staff'] | Array.new([current_user.user_key])
	    @dil_collection = DILCollection.new(:pid=>mint_pid("dil-local"))
		@dil_collection.apply_depositor_metadata(current_user.user_key)
		@dil_collection.edit_users = edit_users_array
		# This allows ALL Collections created by users to be available for anyone with the link
		@dil_collection.read_groups = ["registered"]
		#@dil_collection.set_collection_type('dil_collection')
		@dil_collection.descMetadata.title = params[:dil_collection][:title]
		@dil_collection.save!
	  end
	  redirect_to :back
  end

  def update
    @collection = DILCollection.find(params[:id])
    authorize! :update, @collection
    read_groups = params[:dil_collection].delete(:read_groups)
    if read_groups.present?
      eligible = current_user.owned_groups.map(&:code)
      @collection.set_read_groups(read_groups, current_user.owned_groups.map(&:code))
    end
    @collection.update_attributes(params[:dil_collection])
    if @collection.save
      flash[:notice] = "Saved changes to #{@collection.title}"
    else
      flash[:alert] = "Failed to save your changes!"
    end
    redirect_to dil_collection_path(@collection)
  end
 
  # This method is for adding an image or collection to an existing collection
  # It was originally for adding one item at a time, with that item's id in the params.
  # It can now add multiple items in one call. The hydra-batch-edit gem already had a way to
  # select multiple items from a search result.  It stores the list of selected items in the session.
  # This code now checks to see if there are multiple items in the list.  If so, it will make a call to
  # collection.insert_member for each one.
  def add
    collection = DILCollection.find(params[:id])
    # Does user have edit access on the collection?
    authorize! :edit, collection
        
    # Check to see if there is a batch_select_ids session variable that has values.
    # If so, iterate through and add those items to the collection
    if session[:batch_select_ids].present?
      
      #assign to variable in this scope so the session can be cleared right away
      #for the page refresh 
      pid_list = session[:batch_select_ids]
      
      #Clear the session variable
      session.delete(:batch_select_ids)
      
      # Make sure the selected image is in the list (user might not have checked it)
      if !pid_list.include? (params[:member_id])
        pid_list << params[:member_id]
      end
      
      pid_list.each do |pid|
        fedora_object = ActiveFedora::Base.find(pid, :cast=>true)
        
        # Does user have read access on the item?
        authorize! :show, fedora_object
        
        # Add to collection
        collection.insert_member(fedora_object)
      end
    
    else
      fedora_object = ActiveFedora::Base.find(params[:member_id], :cast=>true)
    
      # Does user have read access on the item?
      authorize! :show, fedora_object
      collection.insert_member(fedora_object)
    end
    
    render :nothing => true
  end

  
  #remove an image or subcollection from the collection
  def remove
    member_index = params[:member_index];
    collection = DILCollection.find(params[:id])
    authorize! :update, collection
    collection.remove_member_by_pid(params[:pid])
    
    redirect_to dil_collection_path(collection)
  end
  
  #delete the collection
  def destroy
    begin
      collection = DILCollection.find(params[:id])
      authorize! :destroy, collection
    
    #remove all members from collection's mods and rels-ext, and update members rels-ext, too
      #collection.members.find_by_terms(:mods, :relatedItem, :identifier).each do |member_pid|
       # collection.remove_member_by_pid(member_pid)
      #end
     
      ##remove collection from parent collections' mods and rels-ext and it's own rels-ext and mods
      #collection.parent_collections.each do |parent_collection|
        #parent_collection.remove_member_by_pid(collection.pid)
     # end
    
    #remove all images from collection
      collection.multiresimages.each do |image|
        collection.remove_member_by_pid(image.pid)
      end
    
      #remove all subcollections from collection
      collection.subcollections.each do |subcollection|
        collection.remove_member_by_pid(subcollection.pid)
      end
      
      #remove collection from parent collections
      collection.parent_collections.each do |parent_collection|
        parent_collection.remove_member_by_pid(collection.pid)
      end
      
      #delete the DILCollection object
      collection.delete
      flash[:notice] = "Image Group deleted"
    
    rescue Exception => e
      flash[:error] = "Error deleting Image Group"
      logger.debug("ERROR ERROR #{e.to_s}")
    
    ensure 
      redirect_to catalog_index_path
    end
  
  end
  
  #move a member item in a collection from original position to new position
  def move
    collection = DILCollection.find(params[:id])
    authorize! :update, collection
	ds = collection.datastreams["members"]
    
    #call the move_member method within mods_collection_members
    ds.move_member(params[:from_index], params[:to_index])
    collection.save!
	render :nothing => true
  end
  
  def show
    @collection = DILCollection.find(params[:id])
    authorize! :show, @collection
#    if can?(:edit, @collection)
       #NEEDED FOR BATCH EDIT
       #get all the solr docs to be used by batch-edit in the view (solr helper is in controller scope, but needed in view) 
       #@solr_docs = []
       #@collection.members.find_by_terms(:mods).each_with_index do |mods|
        # pid = mods.search('relatedItem/identifier').first.text() unless mods.search('relatedItem/identifier').empty?
         #@solr_docs << get_solr_response_for_doc_id(pid)
      #end
      
#      render :action => 'edit', :id => params[:id]
    
#    end
    
  end

# Edit is now unecessary since both show and edit can be handled by the same partial
#  def edit
#    @collection = DILCollection.find(params[:id])
#    authorize! :edit, @collection
    #NEEDED FOR BATCH EDIT
    #get all the solr docs to be used by batch-edit in the view (solr helper is in controller scope, but needed in view) 
    #@solr_docs = []
    #@collection.members.find_by_terms(:mods).each_with_index do |mods|
      #pid = mods.search('relatedItem/identifier').first.text() unless mods.search('relatedItem/identifier').empty?
      #@solr_docs << get_solr_response_for_doc_id(pid)
    #end
    
#  end
  
  def export
    @collection = DILCollection.find(params[:id])
    authorize! :update, @collection
    #read_groups = params[:dil_collection].delete(:read_groups)
    #if read_groups.present?
      #eligible = current_user.owned_groups.map(&:code)
      #@collection.set_read_groups(read_groups, current_user.owned_groups.map(&:code))
    #end
    
    export_xml = @collection.export_image_info_as_xml(current_user.email)
    #export_xml << current_user.email
    logger.debug("export_xml: " + export_xml)
	# response will be status of script that puts message in queue
	logger.debug("Before CGI call for export")
	post_args = {'xml' => export_xml}
	cgi_response = Net::HTTP.post_form(URI.parse(DIL_CONFIG['dil_ppt_cgi_url']), 'collection_xml' => export_xml).body
	logger.debug("After CGI call for export")
	logger.debug("response:" + cgi_response)

    flash[:notice] = "Image Group exported.  Please check your Northwestern University email account for a link to your presentation."
    
    redirect_to dil_collection_path(@collection)
  end
  
  
  
  #This will return all the subcollections of the collection
  def get_subcollections
    begin 
      collection = DILCollection.find(params[:id])
      authorize! :show, collection
    
      #get the json
      return_json = collection.get_subcollections_json
    
    rescue Exception => e
      #error
      return_json = "{\"status\":exception}"
      logger.debug("get_subcollections exception: #{e.to_s}")
        
    ensure #this will get called even if an exception was raised
      respond_to do |format|
        #This wasn't working quite right, so just storing JSON in a variable instead of using .to_json
        #format.json { render :layout =>  false, :json => collection.to_json(:methods=>:get_subcollections) }
        format.json { render :layout =>  false, :json => return_json}
      end  
    
    end
  end
  
   #TODO: Move code to lib directory as this is an API
   # API to return a user's collections' titles and pids as JSON
   def get_collections
    begin
      return_json = ""
      collection_json = current_user.collections.to_json
      #if user logged in
      if current_user.present? and collection_json.present?
        # get the array of Solr results for the user's collections
        return_json = collection_json
      else
        return_json = "{\"status\":exception}"
      end
    rescue Exception => e
      #error
      return_json = "{\"status\":exception}"
      logger.error("get_collections exception: #{e.to_s}")
        
    ensure #this will get called even if an exception was raised
      respond_to do |format|
        #This wasn't working quite right, so just storing JSON in a variable instead of using .to_json
        #format.json { render :layout =>  false, :json => collection.to_json(:methods=>:get_subcollections) }
        format.json { render :layout =>  false, :json => return_json}
      end  
    
    end
    
  end
  
  # This API is called when a user selects one image using the checkbox to add it to the batch selection list.
  # The list is stored in the session as :batch_select_ids
  # JSON is returned
  def add_to_batch_select
    begin 
     
     # If session variable exists and doesn't include the id already, add it to the array
     if session[:batch_select_ids].present? and !session[:batch_select_ids].include? (params[:id])
       session[:batch_select_ids] << params[:id]
       return_json = "{\"status\":\"success\", \"size\":\"#{session[:batch_select_ids].size}\"}"
     elsif !session[:batch_select_ids].present?
     # Create the session variable and add the pid
       (session[:batch_select_ids] ||= []) << params[:id]
       return_json = "{\"status\":\"success\", \"size\":\"1\"}"
     else
       return_json = "{\"status\":\"success,dup\"}"
     end

    rescue Exception => e
      #error
       return_json = "{\"status\":\"exception\"}"
  
    ensure #this will get called even if an exception was raised
      respond_to do |format|
       format.json { render :layout =>  false, :json => return_json}
      end  
    
    end
  end
  
  # This API is called when a user de-selects one image using the checkbox to remove it from the batch selection list.
  # The list is stored in the session as :batch_select_ids
  # JSON is returned
  def remove_from_batch_select
    begin
      if session[:batch_select_ids].present?
        session[:batch_select_ids].delete(params[:id])
        return_json = "{\"status\":\"success\", \"size\":\"#{session[:batch_select_ids].size}\"}"
      else
        return_json = "{\"status\":\"was_empty\"}"
      end
    rescue Exception => e
       #error
       return_json = "{\"status\":\"exception\"}"
    ensure #this will get called even if an exception was raised
      respond_to do |format|
       format.json { render :layout =>  false, :json => return_json}
      end  
    
    end
  end
  
end
