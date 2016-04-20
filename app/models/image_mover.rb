require 'open3'

class ImageMover < ActiveRecord::Base

  DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]
  # This is sort of a weird class, but we created it so we could use the delayed_jobs gem to run the copying of huge tiff (and jp2) files to repository in the background and not effect the responsiveness of the entire app.

  def self.move_jp2_to_ansel(jp2_img_name, jp2_img_path)
    if Rails.env == "development" or Rails.env == "test"
      puts "assume the jp2 image was successfully moved"
    else
      repo_location = "#{ DIL_CONFIG[ 'jp2_location' ]}#{ jp2_img_name }"
      Delayed::Worker.logger.debug "UPLOADING ..."
      Delayed::Worker.logger.debug("scp cmd: scp -i #{ DIL_CONFIG['path_to_keyfile']} #{ jp2_img_path } #{ DIL_CONFIG['jp2_ssh_user'] }@#{DIL_CONFIG['jp2_server']}:#{DIL_CONFIG['jp2_location']}")

      stdout, stdeerr, status = Open3.capture3("scp -i #{ DIL_CONFIG['path_to_keyfile']} #{ jp2_img_path } #{ DIL_CONFIG['jp2_ssh_user'] }@#{DIL_CONFIG['jp2_server']}:#{DIL_CONFIG['jp2_location']}")
      Delayed::Worker.logger.debug("out #{stdout}")
      Delayed::Worker.logger.debug("err #{stdeerr}")
      Delayed::Worker.logger.debug("status #{status}")
      $?
    end
  end

  def self.move_tiff_to_repo(tiff_img_name, tiff_img_path)
    Delayed::Worker.logger.debug tiff_img_name
    Delayed::Worker.logger.debug tiff_img_path

    if Rails.env == "development" or Rails.env == "test"
      Delayed::Worker.logger.debug "assume the tiff image was successfully moved"
    else
      #needs to be in config
      new_path = "#{ DIL_CONFIG['repo_location']}#{ tiff_img_name }"
      old_path = tiff_img_path

      Delayed::Worker.logger.debug "Moving tiff to #{new_path}"
      begin
        FileUtils.mkdir_p File.dirname(new_path)
        FileUtils.mv old_path, new_path
        Delayed::Worker.logger.info "#{old_path} has been moved to #{new_path}"
      rescue StandardError => e
        Delayed::Worker.logger.error "the copy failed because #{e}"
      end
    end
  end
end
