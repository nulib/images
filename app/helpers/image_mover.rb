module ImageMover
  def self.move_img_to_repo(source_path)
    if Rails.env.staging? || Rails.env.production?
      raise "Wrong image format, not tif" unless File.extname(img_name) == ".tif"
      destination_path = "#{DIL_CONFIG['repo_location']}#{ File.basename(source_path) }"
      FileUtils.mv(source_path, destination_path)
    end
  end
end
