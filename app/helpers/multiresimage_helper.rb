module MultiresimageHelper
 
  def get_work_object(work_pid)
	  Vrawork.find(work_pid)
  end

  def get_preferred_work_object(preferred_work_pid)
	  get_work_object(preferred_work_pid) 
  end

  def get_longside_max(image_object)
    ds = image_object.DELIV_OPS
    if ds.svg_rect.empty?
      svg_height = ds.svg_image.svg_height.first.to_i
      svg_width = ds.svg_image.svg_width.first.to_i
    else
      svg_height = ds.svg_rect.svg_rect_height.first.to_i
      svg_width = ds.svg_rect.svg_rect_width.first.to_i
    end
    svg_height > svg_width ? svg_height : svg_width
  end
end
