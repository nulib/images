class InstitutionalCollectionsController < CatalogController
  before_action :authenticate_user!
  before_action :require_admin

  include Blacklight::Configurable
  include Blacklight::SearchHelper

  copy_blacklight_config_from(CatalogController)

  respond_to :html

  # GET /institutional_collections
  def index
    @institutional_collections = InstitutionalCollection.all
    #Dont show DIL since it's not a public collection
    @institutional_collections.delete(InstitutionalCollection.find(DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]))
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
    @collection_id = params[:id]
    @collection = InstitutionalCollection.find(params[:id])
    (@response, @document_list) = get_search_results
  end

  # GET /institutional_collections/1/add_images
  def add_images
    @collection_id = params[:id]
    @collection = InstitutionalCollection.find(params[:id])
    # Only images from DIL are available to add to the collection. 
    query_params = { :q => "-is_governed_by_ssim:" + @collection_id + " "+ params[:q],
                     :f => params[:f]}
    (@response, @document_list) = get_search_results(query_params)
    #extract pids to List
    @pid_list = []
    @document_list.each do |document|
      @pid_list << document[:id]
    end
  end

  # POST /institutional_collections/1/remove_image/:image_id
  def remove_image
    @collection_id = params[:id]
    collection = InstitutionalCollection.find(@collection_id)
    dil_collection = InstitutionalCollection.find(DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"])
    image = Multiresimage.find(params[:image_id])
    image.update_institutional_collection(dil_collection)
    image.save

    flash[:success]="Image was successfully removed from collection"
    redirect_to :action => 'images', :id => @collection_id, 'f[institutional_collection_title_facet][]' => collection.collection_title_formatter
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
  end

  # GET /institional_collections/1/edit
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
                    :description=>params[:institutional_collection][:description]}
      if @institutional_collection.update_attributes(attr_hash)
        flash[:success]="Collection info successfully updated"
        redirect_to institutional_collections_path
      else
        render :action => :edit
      end
    end
  end

  # this is for the little popup that displays the rights description on the homepage
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
    #default to public collection, DIL is the only private collection
    #@collection.default_permissions=[{:type=>"group", :access=>"read", :name=>"public"}]
    @collection.make_public
    @collection.save!

    if @collection.persisted?
      flash[:success]="Collection was successfully created"
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


  def remove
    #TODO delete collection. We will need to change the is_governed_by to default or private and is_representative_of_collection properties on its members first. (They should go back into DIL)
  end

  private

  def require_admin
    unless current_user && current_user.admin?
      flash[:error] = "You're a jerk"
      redirect_to root_path
    end
  end

end
