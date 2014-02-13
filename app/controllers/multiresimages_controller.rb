require 'dil/multiresimage_service'
#require 'dil/pid_minter'

class MultiresimagesController < ApplicationController
  include DIL::MultiresimageService
  #include DIL::PidMinter
  #include Vrawork
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
   
  def edit
    begin
      LockedObject.obtain_lock(params[:id], "image - edit metadata", current_user.id)
      @multiresimage = Multiresimage.find(params[:id])
      authorize! :update, @multiresimage
      #@policies = AdminPolicy.readable_by_user(current_user)
    ensure
      LockedObject.release_lock(params[:id])
    end
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
   
  # Create new crop
  # Todo: Refactor a bunch of this into the model
  def create_crop
        
    # Get source Fedora object
    begin
      image_id = params[:pid]
      LockedObject.obtain_lock(params[:pid], "image - generate detail", current_user.id) 
      source_fedora_object = Multiresimage.find(image_id)
    
      authorize! :show, source_fedora_object
    
      # Get the new crop boundaries
      x=params[:x]
      y=params[:y]
      width=params[:width]
      height=params[:height]
    
      new_image = Multiresimage.new(:pid=>mint_pid("dil-local"))
      #puts "\nNEW IMAGE: x:" + x  + "y:" + y  + "width:" + width  + "height:" + height  + "\n"
	  #@dil_collection.set_collection_type('Multiresimage')

      # Get source SVG datastream
      source_svg_ds = source_fedora_object.DELIV_OPS   
    
      # Get new SVG datastream
      new_svg_ds = new_image.DELIV_OPS 

      # Get source <image> for copying
      image_node = source_svg_ds.find_by_terms(:svg_image)
    
      # Add the <image> object
      new_svg_ds.add_image(image_node)

	  # Update SVG
      new_svg_ds.add_rect(x, y, width, height)
    
      #Add properties datastream with depositor (user) info
      new_image.apply_depositor_metadata(current_user.user_key)
    
      #new_svg_ds.dirty = true
      new_image.save!

      # Get source VRA datastream
      source_vra_ds = source_fedora_object.datastreams["VRA"]
      #source_vra_image=source_vra_ds.find_by_terms(:vra) 
      #vra_ds = new_image.VRA
      #vra_ds.add_image(source_vra_image)
    
      #copy VRA ds from source image object
      new_image.VRA.content = source_vra_ds.content
    
      #replace pid in VRA with crop's pid 
      new_image.replace_pid_in_vra(image_id, new_image.pid)
	
	  # Add [DETAIL] to title in VRA
	  new_image.titleSet_display = new_image.titleSet_display << " [DETAIL]"
	
  	  # Add image and VRA behavior via their cmodels
      new_image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
      new_image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
    
      #Add isCropOf relationship to crop
      new_image.add_relationship(:is_crop_of, "info:fedora/#{source_fedora_object.pid}")
    
      #Add hasCrop relationship to image
      source_fedora_object.add_relationship(:has_crop, "info:fedora/#{new_image.pid}")
      source_fedora_object.save
    
      #Edit rightsMetadata datastream
      new_image.edit_users=[current_user.user_key]
    
      new_image.save
    
      #add the detail to the detail collection
      personal_collection_search_result = current_user.get_details_collection
      DILCollection.add_image_to_personal_collection(personal_collection_search_result, DIL_CONFIG['dil_details_collection'], new_image, current_user.user_key)
    ensure
      LockedObject.release_lock(params[:pid])
    end
    respond_to do |wants|
      wants.html { redirect_to url_for(:action=>"show", :controller=>"multiresimages", :id=>new_image.pid) }
      wants.xml  { render :inline =>'<success pid="'+ new_image.pid + '"/>' }
    end
  end
  
  # This will only be necessary when using ajax -- even then might not be necessary - MZ 06/18/2012
  # routed to /files/:id/permissions (POST)
  # def permissions
  #   @multiresimage = Multiresimage.find(params[:id])
  #   parse_permissions!(params[:multiresimage])
  #   @multiresimage.update_attributes(params[:multiresimage].reject { |k,v| %w{ Filedata Filename revision}.include? k})
  #   @multiresimage.save
  #   redirect_to edit_multiresimage_path, :notice => render_to_string(:partial=>'multiresimages/permissions_updated_flash', :locals => { :asset => @multiresimage }).html_safe
  # end
 
  def updatecrop
    image_id = params[:id]
    
    # Get the new crop boundaries
    x=params['rect']['x']
    y=params['rect']['y']
    width=params['rect']['width']
    height=params['rect']['height']

	  # Update the SVG Datastream
    document_fedora = Multiresimage.find(image_id)
	  svg_ds = document_fedora.DELIV_OPS   
    svg_ds.update_crop(x, y, width, height)

	  # Save the updated dataastreams
    document_fedora.save
	  render :inline =>'<success pid="'+ image_id + '"/>'	
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
    filename = "download.tif"
    send_data(multiresimage.ARCHV_IMG.content, :disposition=>'inline', :type=>'image/tiff', :filename=>filename)
  end
  
end
