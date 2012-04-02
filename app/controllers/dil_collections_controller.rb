require 'mediashelf/active_fedora_helper'

class DilCollectionsController < ApplicationController

  include MediaShelf::ActiveFedoraHelper
  include Hydra::AssetsControllerHelper
  
  before_filter :require_solr, :require_fedora
 
  def new
	  #af_model = retrieve_af_model('hydrangea_collection')
	  #if af_model
		asset = DILCollection.new()
		if asset.respond_to?(:apply_depositor_metadata) && current_user.respond_to?(:login)
		  asset.apply_depositor_metadata(current_user.login)
		end
		set_collection_type(@asset, 'dil_collection')
		
		descMetadata = asset.datastreams_in_memory["descMetadata"];
		descMetadata.update_indexed_attributes([:title_info, :main_title]=>params[:title]);
		descMetadata.dirty = true
		asset.save
	  #end
	  #redirect_to url_for(:action=>"edit", :controller=>"catalog", :id=>asset.pid)
	  redirect_to url_for(:action=>"index", :controller=>"catalog")
  end
 
  def add
	collection_id = params[:id];
	member_id = params[:member_id];
	member_title = params[:member_title];
	
    #af_model = retrieve_af_model(params[:content_type], :default=>HydrangeaCollection)
    #@document_fedora = af_model.find(collection_id)
    collection = DILCollection.find(collection_id)
    #inserted_node, new_node_index = @document_fedora.insert_member({ :member_id => member_id, :member_title => member_title})
    inserted_node, new_node_index = collection.insert_member({ :member_id => member_id, :member_title => member_title})
    #@document_fedora.save
    collection.save
    render :nothing => true
	#redirect_to url_for(:action=>"index", :controller=>"catalog")
  end
  
  def remove
	collection_id = params[:id];
	member_index = params[:member_index];
	
    #af_model = retrieve_af_model(params[:content_type], :default=>HydrangeaCollection)
    #document_fedora = af_model.find(collection_id)
	#ds = document_fedora.datastreams_in_memory["members"]   
    #ds.remove_member(member_index)
    #document_fedora.save
    
    collection = DILCollection.find(params[:id])
    ds = collection.datastreams["members"]
    ds.remove_member(params[:member_index])
    collection.save
    
    redirect_to url_for(:action=>"edit", :controller=>"dil_collections", :id=>collection_id)
  end
  
  #move a member item in a collection from original position to new position
   def move
	#collection_id = params[:id]
	#from_index = params[:from_index]
	#to_index = params[:from_index]

    #af_model = retrieve_af_model(params[:content_type], :default=>HydrangeaCollection)
    #document_fedora = af_model.find(collection_id)
	collection = DILCollection.find(params[:id])
	#ds = document_fedora.datastreams_in_memory["members"]
	ds = collection.datastreams["members"]
    #call the move_member method within mods_collection_members
    ds.move_member(params[:from_index], params[:to_index])
    #document_fedora.save
    collection.save
	#redirect_to url_for(:action=>"show", :controller=>"catalog", :id=>collection_id)
	render :nothing => true
  end
  
  def show
    @collection = DILCollection.find(params[:id])
	#redirect_to url_for(:action=>"show", :controller=>"catalog", :id=>params[:id])
  end
  
   def edit
    @collection = DILCollection.find(params[:id])
  end

end
