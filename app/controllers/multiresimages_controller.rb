require 'dil/multiresimage_service'
class MultiresimagesController < ApplicationController
  include DIL::MultiresimageService
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
	  source_fedora_object = Multiresimage.find(params[:id])
	  @svg = source_fedora_object.DELIV_OPS.content()
    respond_to do |wants|
       wants.xml  { render :xml => @svg }
    end
  end
 
   # Get Aware's HTML view of the image for screen scraping geometry
  def aware_details
    @aware_details_url = "***REMOVED***" + params[:file_path]
  end

  # Get tile from Aware
  def aware_tile
    tile_url = "***REMOVED***" + params[:file_path] + "&zoom=" + params[:level] + "&x=" + params[:x] + "&y=" + params[:y] + "&rotation=0"  
    send_data Net::HTTP.get_response(URI.parse(tile_url)).body, :type => 'image/jpeg', :disposition => 'inline'
  end
   
  def edit
    @multiresimage = Multiresimage.find(params[:id]) 
    @policies = AdminPolicy.readable_by_user(current_user)
    authorize! :destroy, @multiresimage
  end
   
  def show
    @multiresimage = Multiresimage.find(params[:id])
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
  def create
    image_id = params[:id]

    # Get the new crop boundaries
    x=params[:x]
    y=params[:y]
    width=params[:width]
    height=params[:height]
    
    new_image = Multiresimage.new
    puts "\nNEW IMAGE: x:" + x  + "y:" + y  + "width:" + width  + "height:" + height  + "\n"
    apply_depositor_metadata(new_image)
    set_collection_type(new_image, 'Multiresimage')

    # Get source Fedora object
    source_fedora_object = Multiresimage.find(image_id)

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
    new_svg_ds.dirty = true
    new_image.save

    # Get source VRA datastream
    source_vra_ds = source_fedora_object.VRA
    source_vra_image=source_vra_ds.find_by_terms(:vra_image) 
    vra_ds = new_image.VRA   
    vra_ds.add_image(source_vra_image)
    new_image.save

  	# Add image and VRA behavior via their cmodels
    new_image.add_relationship(:has_model, "info:fedora/inu:VRACModel")
    new_image.add_relationship(:has_model, "info:fedora/inu:imageCModel")
    new_image.save

    respond_to do |wants|
      wants.html { redirect_to url_for(:action=>"show", :controller=>"catalog", :id=>new_image.pid) }
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
  
  
end
