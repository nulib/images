class InstitutionalCollectionsController < CatalogController
  #before_filter :authenticate_user!
  #load_and_authorize_resource except: [:index]
  #before_filter :load_and_authorize_collections, only: [:index]


  include Blacklight::Configurable
  include Blacklight::SearchHelper

  copy_blacklight_config_from(CatalogController)

  respond_to :html


  # GET /institutional_collections
  def index
    @institutional_collections = InstitutionalCollection.all
    respond_to do |format|
      format.html
      format.json { paginate json: @institutional_collections }
    end
  end

  # GET /institutional_collections/1
  def show
    @collection = InstitutionalCollection.find(params[:id])
    respond_to do |format|
      format.json { render json: @collection.to_json }
      format.html {

      }
    end
  end

  # GET /institutional_collections/1/images
  def images
    (@response, @document_list) = get_search_results
  end

  # GET /institutional_collections/1/add_images
  def add_images
    @collection_id = params[:id]
    query_params = { :q => "-is_governed_by_ssim:" + @collection_id + " "+ params[:q],
                     :f => params[:f]}
    (@response, @document_list) = get_search_results(query_params)
    #extract pids to List
    @pid_list = []
    @document_list.each do |document|
      @pid_list << document[:id]
    end

    puts @pid_list

    #render json: @document_list
  end

  def confirm_add_images
    @collection_id = params[:id]
    @pid_list = params[:pid_list]
    @pid_list.each do |pid|
      image = Multiresimage.find(pid)
      image.update_institutional_collection(InstitutionalCollection.find(@collection_id))
      image.save!
    end
    flash[:notice]="Your request to add images to the collection has been placed in the queue. You will recieve an email when your job completes"
    redirect_to institutional_collections_path
  end

  # GET /institional_collections/new
  def new
    @institutional_collection = InstitutionalCollection.new
    render 'new'
  end

  # GET /institional_collections/1/edit
  def edit
    respond_to do |format|
      format.js   { render json: modal_form_response(@collection) }
    end
  end

  def rights
    @collection = InstitutionalCollection.find(params[:id])
  end



  # POST /institional_collections/create
  def create
    faceted_title_params = params[:institutional_collection]
    faceted_title_params[:title] = "#{params[:institutional_collection][:unit_part]}|#{params[:institutional_collection][:title_part]}"

    @collection = InstitutionalCollection.create(faceted_title_params)
    @collection.rightsMetadata
    @collection.default_permissions
    #default to public collection
    @collection.default_permissions=[{:type=>"group", :access=>"read", :name=>"public"}]
    @collection.save!

    if @collection.persisted?
      #render json: {id: @collection.pid}, status: 200
      redirect_to @collection
    else
      logger.warn "Failed to create collection: #{@collection.errors.full_messages}"
      render json: {errors: ["Failed to create collection with these params: #{params[:collection]}"] + @collection.errors.full_messages}, status: 422
    end
  end

  def make_public
    @collection = InstitionalCollection.find(params[:collection])
    #@collection.
  end

  def make_private
    @collection = InstitionalCollection.create(params[:collection])
  end

  def remove
    #will need to change the is_governed_by to default or private and is_representative_of_collection properties on its members first
    InstitutionalCollection.find(params[:id]).destroy
    render json: 'ok', status: 200
  end


end
