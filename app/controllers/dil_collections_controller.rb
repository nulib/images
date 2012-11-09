class DilCollectionsController < ApplicationController
  
  include DIL::PidMinter
  
  def create
    authorize!(:create, DILCollection)
	  #make sure collection's name isn't a reserved name for Uploads and Details collections
	  if params[:dil_collection][:title].downcase == DIL_CONFIG['dil_uploads_collection'].downcase || params[:dil_collection][:title].downcase == DIL_CONFIG['dil_details_collection'].downcase
	    flash[:alert] = "Cannot use that collection name. That name is reserved."
	  else	
	    @dil_collection = DILCollection.new(:pid=>mint_pid("dil-local"))
		@dil_collection.apply_depositor_metadata(current_user.user_key)
		@dil_collection.set_collection_type('dil_collection')
		@dil_collection.descMetadata.title = params[:dil_collection][:title]
		@dil_collection.save!
	  end
	  redirect_to catalog_index_path
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
    redirect_to edit_dil_collection_path(@collection)
  end
 
  def add
    @collection = DILCollection.find(params[:id])
    authorize! :edit, @collection
    @fedora_object = ActiveFedora::Base.find(params[:member_id], :cast=>true)
    authorize! :show, @fedora_object
#  puts "Inserting #{@image.pid} to #{@collection.pid}"
    @collection.insert_member(@fedora_object)
    @collection.save!
    render :nothing => true
  end
  
  def remove
    collection_id = params[:id];
    member_index = params[:member_index];
    collection = DILCollection.find(params[:id])
    ds = collection.datastreams["members"]
    ds.remove_member_by_pid(params[:pid])
    collection.save!
    
    redirect_to edit_dil_collection_path(collection)
  end
  
  #move a member item in a collection from original position to new position
  def move
    collection = DILCollection.find(params[:id])
	#ds = collection.members
	ds = collection.datastreams["members"]
    #call the move_member method within mods_collection_members
    ds.move_member(params[:from_index], params[:to_index])
    collection.save!
	render :nothing => true
  end
  
  def show
    @collection = DILCollection.find(params[:id])
  end
  
  def edit
    @collection = DILCollection.find(params[:id])
    authorize! :edit, @collection
  end
  
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

    flash[:notice] = "Collection exported"
    
    redirect_to edit_dil_collection_path(@collection)
  end

end
