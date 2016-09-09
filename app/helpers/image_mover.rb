module ImageMover
  def self.move_img_to_repo(source_path)
    if Rails.env.staging? || Rails.env.production?
      raise "Wrong image format, not tif" unless File.extname(source_path) == ".tif"
      destination_path = "#{DIL_CONFIG['repo_location']}#{ File.basename(source_path) }"
      logger.info("repo_location exist? #{File.exist?(DIL_CONFIG['repo_location'])}")
      logger.info("destination_path: #{destination_path}")

      logger.info("does the source file exist??? : #{File.exist?(source_path)}")
      logger.info("about to move tif to repo...")
      FileUtils.mv(source_path, destination_path)
      logger.info("after move has been called")
      logger.info("is the tif at the destination? : #{File.exist?(destination_path)}")
    end
  end
end
