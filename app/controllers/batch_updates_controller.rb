class BatchUpdatesController < ApplicationController
  
  cattr_accessor :type

  self.type = :multiresimage
  
  # fetch the documents that match the ids in the folder
  def index
    @response, @documents = get_solr_response_for_field_values("id",session[:batch_document_ids] || [])
  end

  # add a document_id to the batch. :id of action is solr doc id 
  def add
    batch << params[:id] 
    respond_to do |format|
      format.html do
        redirect_to :back, :notice =>  "#{params[:title] || "Item"} successfully added to batch"
      end
      format.js { render :json => session[:batch_document_ids] }
    end
  end
 
  # remove a document_id from the batch. :id of action is solr_doc_id
  def destroy
    batch.delete(params[:id])
    respond_to do |format|
      format.html do
        redirect_to :back, :notice => "#{params[:title] || "Item"} successfully removed from batch"
      end
      format.js do
        render :json => {"OK" => "OK"}
      end
    end
          
  end
 
  # get rid of the items in the batch
  def clear
    session[:batch_document_ids] = []
    respond_to do |format|
      format.html { redirect_to :back, :notice=> "Batch has been cleared" }
      format.js { render :json => session[:batch_document_ids] }
    end
  end

  def edit
    filter_docs_with_access!
    if batch.empty?
      redirect_to :back 
      return
    end
  end

  def update
    filter_docs_with_access!
    if batch.empty?
      redirect_to catalog_index_path
      return
    end
    batch.each do |doc_id|
      obj = ActiveFedora::Base.find(doc_id, :cast=>true)
      obj.update_attributes(params[self.class.type])
      obj.save
    end
    flash[:notice] = "Batch update complete"
    session[:batch_document_ids] = []
    redirect_to catalog_index_path
    
  end

  private

  def batch
    session[:batch_document_ids] ||= []
  end
  
  def filter_docs_with_access!
    no_permissions = []
    if batch.empty?
      flash[:notice] = "Select something first"
    else
      batch.dup.each do |doc_id|
        unless can?(:edit, doc_id)
          session[:batch_document_ids].delete(doc_id)
          no_permissions << doc_id
        end
      end
      flash[:notice] = "You do not have permission to edit the documents: #{no_permissions.join(', ')}" unless no_permissions.empty?
    end
  end

end
