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
    # Clean up any associated VRAWork objects
    if obj.vraworks[0].present?
      obj.vraworks[0].delete
    end
    # Delete the Multiresimage itself finally
    obj.delete
    redirect_to catalog_index_path, :notice=>"Image has been deleted"
  end

  def update_vra
    #this method updates both image and work vra.
    #it replaces the content of the work with the updated image xml,
    #with two exceptions: the DIL refid node and the nodeSet for the relation set.
    image = Multiresimage.find(params[:pid])
    work_pid = image.preferred_related_work_pid

    work = Multiresimage.find(work_pid)
    work_xml = work.datastreams['VRA'].content

    image_metadata = Nokogiri::XML(params[:xml])
    work_metadata = Nokogiri::XML(work_xml)

    work_node = work_metadata.at_xpath("//vra:work")

    image_metadata.at_xpath("//vra:refid[@source='DIL']").swap(work_metadata.at_xpath("//vra:refid[@source='DIL']"))
    image_metadata.at_xpath("//vra:relationSet").swap(work_metadata.at_xpath("//vra:relationSet"))

    work_metadata.xpath("//vra:work").children.remove
    work_node.children = image_metadata.xpath("//vra:image").children

    updated_work_xml = work_metadata.to_xml

    image.datastreams['VRA'].content = params[:xml]
    image.save

    work.datastreams['VRA'].content = updated_work_xml
    work.save

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
        # Delete the work and image if creation fails
        if i
          logger.info "Deleting work and image because #{msg}"
          i.vraworks.first.delete if i.vraworks.first
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
    if multiresimage.relationships(:is_governed_by) == ["info:fedora/inu:dil-932ada6f-5cce-45c8-a6b9-139e1e1f281b"]
      filename = "download.tif"
      send_data(multiresimage.ARCHV_IMG.content, :type=>'image/tiff', :filename=>filename) unless multiresimage.ARCHV_IMG.content.nil?
    else
      render :nothing => true
    end
  end

end
