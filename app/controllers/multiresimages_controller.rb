require 'dil/pid_minter'

class MultiresimagesController < ApplicationController
  include DIL::PidMinter
  helper :permissions

  respond_to :html, :xml

  def destroy
    obj = Multiresimage.find(params[:id])
    authorize! :destroy, obj
    # First remove from all dil collections
    obj.remove_from_all_dil_collections

    # Delete the Multiresimage itself finally
    obj.delete
    redirect_to catalog_index_path, :notice=>"Image has been deleted"
  end

  def update_vra
    image = Multiresimage.find(params[:pid])

    image_metadata = Nokogiri::XML(params[:xml])

    image.datastreams['VRA'].content = params[:xml]
    image.save

    fedora_object = ActiveFedora::Base.find(params[:pid], :cast=>:true)
    fedora_object.update_index

    head :ok
  end

  def create
    if params[:path] && params[:xml] && params[:accession_nbr]
      begin
        raise "An accession number is required" if params[:accession_nbr].blank?
        raise "Existing image found with this accession number" if Multiresimage.existing_image?( params[:accession_nbr] )

        i = Multiresimage.new(pid: mint_pid("dil"), vra_xml: params[:xml], from_menu: params[:from_menu])
        i.save

        i.create_datastreams_and_persist_image_files(params[:path])

        returnXml = "<response><returnCode>Publish successful</returnCode><pid>#{i.pid}</pid></response>"
      rescue StandardError => msg
        returnXml = "<response><returnCode>Error</returnCode><description>#{msg}</description></response>"
        # Should we wrap everything in a transaction? Or try to delete the fedora object if the creation fails?
        # Delete the image if creation fails
        if i
          logger.info "Deleting image because #{msg}"
          i.delete
        end
        logger.debug returnXml
      end
    else
      returnXml = "<response><returnCode>Error</returnCode><description>menu_publish requires both image path and VRA xml.</description></response>"
    end
    respond_to do |format|
      format.xml {render :layout => false, :xml => returnXml}
    end
  end


  def show
    unless params[:pid].nil?
      @collection = DILCollection.find(params[:pid])
    end
    unless params[:index].nil?
      @index = params[:index]
    end

    @display_content_nav_elements = @collection.present? && @collection.show_navigation_elements? && @index.present?

    begin
      session[:previous_url] = request.fullpath unless request.xhr?

      @multiresimage = Multiresimage.find(params[:id])
      authorize! :read, @multiresimage
    rescue Blacklight::Exceptions::InvalidSolrID => e
      if !user_signed_in?
        flash[:error] = "You must log in to view this image."
        redirect_to  "/users/sign_in"
      else
        redirect_to "/server_error"
      end
    end

    @user_with_groups_is_signed_in = false
    if user_signed_in? and !current_user.collections.empty?
      @user_with_groups_is_signed_in = true
    end

    @page_title = @multiresimage.titleSet_display
  end

  def get_vra(pid=params[:pid])
    @vra_url = "http://#{DIL_CONFIG['repo_server']}/fedora/objects/#{pid}/datastreams/VRA/content"
    @res = Net::HTTP.get(URI(@vra_url))
    render xml: @res
  end

  def archival_image_proxy
    multiresimage = Multiresimage.find(params[:id])
    logger.info "Request to download tif: #{params[:id]}"
    if multiresimage.relationships(:is_governed_by) == ["info:fedora/inu:dil-932ada6f-5cce-45c8-a6b9-139e1e1f281b"]  || current_user.admin?
      if multiresimage.ARCHV_IMG.dsLocation == nil
        logger.error "ARCHV-IMG.dsLocation for image is nil: #{params[:id]}"
        flash[:error] = "No TIF location (path) associated with this image."
        redirect_to multiresimage_path
      else
        begin
          filename = "download.tif"
          send_data(multiresimage.ARCHV_IMG.content, :type=>'image/tiff', :filename=>filename) unless multiresimage.ARCHV_IMG.content.nil?
        rescue => e
          logger.error "Problem retrieving tif file: #{multiresimage.ARCHV_IMG.dsLocation}: #{e.class}, #{e.message}"
          flash[:error] = "Problem retrieving tif file:  #{multiresimage.ARCHV_IMG.dsLocation}: #{e.class}, #{e.message}"
          redirect_to multiresimage_path
        end
      end
    else
      logger.error "Not authorized to download tif: #{params[:id]}"
      render :nothing => true
    end
  end

end
