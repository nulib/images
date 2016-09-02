class InstitutionalCollectionsController < CatalogController
  before_action :authenticate_user!
  before_action :require_admin

  include Blacklight::Configurable
  include Blacklight::SearchHelper
  include Blacklight::UrlHelperBehavior
  include Sidekiq::Worker

  copy_blacklight_config_from(CatalogController)

  respond_to :html

  # GET /institutional_collections
  def index
    @institutional_collections = InstitutionalCollection.all
    #Dont show DIL since it's not a public collection
    @institutional_collections.delete(InstitutionalCollection.find(DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]))
  end

  # GET /institutional_collections/1
  def show
    @collection = InstitutionalCollection.find(params[:id])
  end

  # GET /institutional_collections/1/images
  def images
    @collection_id = params[:id]
    @collection = InstitutionalCollection.find(params[:id])
    
    page = params.fetch(:page, 1).to_i
    
    solr_params = {
      :page => page,
      :per_page => 10, 
      :q => params[:q],
      :f => params[:f]
    }

    (@response, @document_list) = search_results(solr_params, search_params_logic)
    search_session[:total] = @response.total unless @response.nil?
  end

  # GET /institutional_collections/1/add_images
  def add_images
    @collection_id = params[:id]
    @collection = InstitutionalCollection.find(params[:id])

    page = params.fetch(:page, 1).to_i
    solr_params = {
      :page => page,
      :per_page => 10, 
      :q => params[:q]
    }
    # Only images from DIL are available to add to the collection. 
    self.search_params_logic += [:dil_collection_filter]
    (@response, @document_list) = search_results(solr_params, search_params_logic)
    search_session[:total] = @response.total unless @response.nil?

    (@all_id_response, @all_id_docs) = search_results({ q: params[:q] }, search_params_logic+[:all_ids_filter])
    @pid_list = @all_id_docs.collect { |d| d['id'] }
  end

  # POST /institutional_collections/1/remove_image/:image_id
  def remove_image
    @collection_id = params[:id]
    collection = InstitutionalCollection.find(@collection_id)
    dil_collection = InstitutionalCollection.find(DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"])
    image = Multiresimage.find(params[:image_id])
    image.update_institutional_collection(dil_collection)
    image.save

    flash[:success] = "Image was successfully removed from collection"
    redirect_to :action => 'images', :id => @collection_id, 'f[institutional_collection_title_facet][]' => collection.collection_title_formatter
  end

  def confirm_add_images
    AddInstitutionalCollectionWorker.add_to_collection(params[:id], params[:pid_list])
    flash[:notice] = "Your request to add images to the collection has been placed in the queue. Check the sidekiq process to monitor for errors"
    redirect_to institutional_collections_path
  end

  # GET /institutional_collections/new
  def new
    @institutional_collection = InstitutionalCollection.new
  end

  # GET /institutional_collections/1/edit
  def edit
    @institutional_collection = InstitutionalCollection.find(params[:id])
  end

  def update
    # do not allow changing the title and unit after collection
    # creation. (If we do change these after creation and the collection has images,
    # keep in mind that we must at minimum reindex the associated images)
    @institutional_collection = InstitutionalCollection.find params[:id]

    if ( params[:institutional_collection][:rights_description] or params[:institutional_collection][:description] )
      attr_hash = { :rights_description=> params[:institutional_collection][:rights_description],
                    :description=>params[:institutional_collection][:description], :thumbnail_url=> params[:institutional_collection][:thumbnail_url] }
      if @institutional_collection.update_attributes(attr_hash)
        flash[:notice] = "Collection info successfully updated"
        redirect_to institutional_collection_path(@institutional_collection)
      else
        render :action => :edit
      end
    end
  end

  # this is for the little popup that displays the rights description on the homepage
  def rights
    @collection = InstitutionalCollection.find(params[:id])
  end

  # POST /institutional_collections/create
  def create
    faceted_title_params = params[:institutional_collection]
    faceted_title_params[:title] = "#{params[:institutional_collection][:unit_part]}|#{params[:institutional_collection][:title_part]}"

    @collection = InstitutionalCollection.create(faceted_title_params)
    @collection.rightsMetadata
    @collection.default_permissions
    #default to public collection, DIL is the only private collection
    #@collection.default_permissions=[{:type=>"group", :access=>"read", :name=>"public"}]
    @collection.make_public
    @collection.save!

    if @collection.persisted?
      flash[:success] = "Collection was successfully created"
      redirect_to @collection
    else
      logger.warn "Failed to create collection: #{@collection.errors.full_messages}"
      render 'new'
    end
  end

  def collection_name_ok
    #TODO placeholder to remember to check wither the name of the collection is already in use, etc
    return true
  end


  def destroy
    raise "Can't delete DIL Collection" if params[:id] == DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]
    RemoveInstitutionalCollectionWorker.perform_async(params[:id])
    flash[:notice] = "Institutional Collection removal has been placed in the queue. Check the sidekiq process to monitor for errors"
    redirect_to institutional_collections_path
  end

  private

  def require_admin
    unless current_user && current_user.admin?
      flash[:error] = "You do not have the necessary permissions to view this page"
      redirect_to root_path
    end
  end

  def all_ids_filter(solr_params, user_params)
    solr_params[:rows] = @response.total
    solr_params[:fl] = 'id'
  end

  def dil_collection_filter(solr_params, user_params)
    solr_params[:fq] ||= []
    # solr_params[:fq] << "-is_governed_by_ssim:\"inu:dil-00-23655b1f-7029-4fb4-aa10-8ababe0ca63b\""
    solr_params[:fq] << "+institutional_collection_title_ssim:\"Digital Image Library\""
  end
end
