require 'dil/multiresimage_service'
require 'dil/pid_minter'

class MultiresimagesController < ApplicationController
  include DIL::MultiresimageService
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


  # Get SVG for id
  def get_svg
	  expires_in(1.hours, :private => false, :public => true)
	  source_fedora_object = Multiresimage.find(params[:id])
	  authorize! :show, source_fedora_object
	  @svg = source_fedora_object.DELIV_OPS.content()
    gon.url = DIL_CONFIG['dil_js_url']
    respond_to do |wants|
       wants.xml  { render :xml => @svg }
    end
  end

   # Get Aware's HTML view of the image for screen scraping geometry
  def aware_details
    @aware_details_url = "#{DIL_CONFIG['dil_aware_detail_url']}#{params[:file_path]}"
  end

  # Get tile from Aware
  def aware_tile
    tile_url = "#{DIL_CONFIG['dil_aware_tile_url']}#{params[:file_path]}&zoom=#{params[:level]}&x=#{params[:x]}&y=#{params[:y]}&rotation=0"
    #logger.debug("tile_url:#{tile_url}")
    expires_in(1.hours, :private => false, :public => true)
    send_data Net::HTTP.get_response(URI.parse(tile_url)).body, :type => 'image/jpeg', :disposition => 'inline'
  end

  def update_vra
    #this method updates both image and work vra.
    #it replaces the content of the work with the updated image xml,
    #with two exceptions: the DIL refid node and the nodeSet for the relation set.
    image = Multiresimage.find(params[:pid])
    work_pid = image.preferred_related_work_pid

    work = Multiresimage.find(work_pid)
    work_xml = work.datastreams['VRA'].content

    #because u might need it in the rescue
    image_xml = image.datastreams['VRA'].content

    image_metadata = Nokogiri::XML(params[:xml])
    work_metadata = Nokogiri::XML(work_xml)
    work_node = work_metadata.at_xpath("//vra:work")

    image_metadata.at_xpath("//vra:refid[@source='DIL']").swap(work_metadata.at_xpath("//vra:refid[@source='DIL']"))
    image_metadata.at_xpath("//vra:relationSet").swap(work_metadata.at_xpath("//vra:relationSet"))

    work_metadata.xpath("//vra:work").children.remove
    work_node.children = image_metadata.xpath("//vra:image").children

    updated_work_xml = work_metadata.to_xml
    status = 200
    update_work = true

    begin
      update_fedora_object(params[:pid], params[:xml], "VRA", "VRA", "text/xml")
    rescue StandardError => msg
      puts "image is not happening"
      puts "Error -- update_fedora_object image: #{msg}"
      status = 500
      update_work = false
    end

    if update_work
      begin
        update_fedora_object(work_pid, updated_work_xml, "VRA", "VRA", "text/xml")
      rescue StandardError => msg
        logger.error "Error -- update_fedora_object work: #{msg}"
        update_fedora_object(params[:pid], image_xml, "VRA", "VRA", "text/xml")
        status = 500
      end
    end

    head status
  end

  def create
    logger.debug "multiresimages/create was just called with this from_menu param: #{params[:xml]}"
    if params[:path] && params[:xml] && params[:accession_nbr]
      begin
        raise "An accession number is required" if params[:accession_nbr].blank?
        raise "Existing image found with this accession number" if existing_image?( params[:accession_nbr] )
        i = Multiresimage.new(pid: mint_pid("dil"), vra_xml: params[:xml], from_menu: params[:from_menu])
        i.save
        puts "Images path #{params[:path]}"
        i.create_datastreams_and_persist_image_files(params[:path])
        returnXml = "<response><returnCode>Publish successful</returnCode><pid>#{i.pid}</pid></response>"
      rescue StandardError => msg
        # puts msg.backtrace.join("\n")
        returnXml = "<response><returnCode>Error</returnCode><description>#{msg}</description></response>"
        # Should we wrap everything in a transaction? Or try to delete the fedora object if the creation fails?
        # Delete the work and image if creation fails
        if i
          logger.debug "Deleting work and image because #{msg}"
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

    @multiresimage = Multiresimage.find(params[:id])
    authorize! :read, @multiresimage

    @user_with_groups_is_signed_in = false
    if user_signed_in? and !current_user.collections.empty?
      @user_with_groups_is_signed_in = true
    end
    @page_title = @multiresimage.titleSet_display
    gon.url = DIL_CONFIG['dil_js_url']
  end

  def get_vra(pid=params[:pid])
    @vra_url = "#{DIL_CONFIG['dil_fedora_vra_url']}objects/#{pid}/datastreams/VRA/content"
  #  DIL_CONFIG['dil_fedora_vra_url']objects/pid/datastreams/VRA/content
  #  http://localhost:8983/fedora/objects/inu:dil-c5275483-699b-46de-b7ac-d4e54112cb60/datastreams/VRA/content
    @res = Net::HTTP.get(URI(@vra_url))
    render xml: @res
  end

  # This method is called from multiresimage/_index.html.erb (image search results).
  # We don't want to show the Fedora URL to the user, so we call this action.
  # The permissions are checked and, if applicable, the image is retrieved and
  # displayed in the browser. The request to Fedora is coming from the app server
  # (and not the user's browser) so the Fedora XACML policy won't reject the request. If an unauthorized
  # user requests the image from Fedora directly, the XACML policy will block them.  If they request it from
  # this action, the permissions check will deny access.

  def proxy_image
    multiresimage = Multiresimage.find(params[:id])

    src_width = multiresimage.DELIV_OPS.svg_image.svg_width.first.to_f
    src_height = multiresimage.DELIV_OPS.svg_image.svg_height.first.to_f

    # Max size is 1600 pixels or less, because we can't give away higher quality versions I guess!
    max_size = [ params[:image_length].to_i, 1600, src_width, src_height ].min

    image_url = multiresimage.image_url(max_size)

    if can?(:read, multiresimage)
      begin
        send_data( Net::HTTP.get_response(URI.parse(image_url)).body, type: 'image/jpeg' )
      rescue
        default_image = File.open("app/assets/images/site/missing2.png", 'rb').read
        filename = "missing2.png"
        send_data( default_image, disposition: 'inline', type: 'image/jpeg', filename: filename )
      end
    end
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
