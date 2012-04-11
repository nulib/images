class DilCollectionsController < ApplicationController
  include Hydra::AssetsControllerHelper

  def create
    authorize!(:create, DILCollection)
		@dil_collection = DILCollection.new()
		@dil_collection.apply_depositor_metadata(current_user.uid)
		set_collection_type(@dil_collection, 'dil_collection')
		@dil_collection.descMetadata.title = params[:dil_collection][:title]
		@dil_collection.save!
	  redirect_to catalog_index_path
  end
 
  def add
    collection = DILCollection.find(params[:id])
    collection.insert_member({ :member_id => params[:member_id], :member_title => params[:member_title]})
    collection.save!
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
	  ds = collection.members
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

end
