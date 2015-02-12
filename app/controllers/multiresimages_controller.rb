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
    if obj.vraworks[0].present?
      obj.vraworks[0].delete
    end
    obj.delete
    selected_files.delete(params[:id])
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


  def show
    if !params[:pid].nil?
      @collection = DILCollection.find(params[:pid])
      if !params[:index].nil?
        @index = params[:index]
      else
        @index = nil
      end
    else
      @collection = nil
      @index = nil
    end
    @multiresimage = Multiresimage.find(params[:id])
    authorize! :read, @multiresimage
    @page_title = @multiresimage.titleSet_display
    gon.url = DIL_CONFIG['dil_js_url']
  end

  def update
    @multiresimage = Multiresimage.find(params[:id])
    authorize! :update, @multiresimage
    read_groups = params[:multiresimage].delete(:read_groups)
    if read_groups.present?
      eligible = current_user.owned_groups.map(&:code)
      @multiresimage.set_read_groups(read_groups, current_user.owned_groups.map(&:code))
    end
    parse_permissions!(params[:multiresimage])
    @multiresimage.update_attributes(params[:multiresimage])
    respond_to do |format|
      format.json do
        render :json=>{:values => params[:multiresimage][:permissions] }
      end
      format.html { redirect_to edit_multiresimage_path(@multiresimage), :notice =>"Saved changes to #{@multiresimage.id}" }
    end
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
    img_length = params[:image_length]

    begin
      if multiresimage.DELIV_OPS.svg_image.svg_width[0].to_i <= params[:image_length].to_i
        img_length = multiresimage.DELIV_OPS.svg_image.svg_width[0].to_i-1
      end
    rescue Exception
      #this is a fix so that smaller images get shown. Currently, they break since larger versions do not exist.
    end

    default_image = File.open("app/assets/images/site/missing2.png", 'rb') do |f|
      f.read
    end
    filename = "missing2.png"
    resp = ''

    if can?(:read, multiresimage)

      Net::HTTP.start(DIL_CONFIG['dil_fedora_base_ip'], DIL_CONFIG['dil_fedora_port']) { |http|
        resp = http.get("#{DIL_CONFIG['dil_fedora_url']}#{params[:id]}#{DIL_CONFIG['dil_fedora_disseminator']}#{img_length}")
        #open("/usr/local/proxy_images/#{params[:id]}.jpg" ,"wb") { |new_file|
          #new_file.write(resp.body)
          #send_file(new_file, :type => "image/jpeg", :disposition=>"inline")
          #send data uses server memory instead of storage.
          if(resp.body.include? "error")
            image = default_image
          else
            image = resp.body
            filename = "#{params[:id]}.jpg"
          end
          send_data(image, :disposition=>'inline', :type=>'image/jpeg', :filename=>filename)
        }
      #}
    else
      send_data(default_image, :disposition=>'inline', :type=>'image/jpeg', :filename=>filename)
    end
  end

  def archival_image_proxy
    multiresimage = Multiresimage.find(params[:id])
    if multiresimage.relationships(:is_governed_by) == ["info:fedora/inu:dil-932ada6f-5cce-45c8-a6b9-139e1e1f281b"]
      filename = "download.tif"
      send_data(multiresimage.ARCHV_IMG.content, :disposition=>'inline', :type=>'image/tiff', :filename=>filename) unless multiresimage.ARCHV_IMG.content.nil?
    else
      render :nothing => true
    end
  end

end
