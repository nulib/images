require 'open3'

class ImageMover < ActiveRecord::Base

  DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]
  # This is sort of a weird class, but we created it so we could use the delayed_jobs gem to run the copying of huge tiff (and jp2) files to repository in the background and not effect the responsiveness of the entire app.

  def self.move_jp2_to_ansel(jp2_img_name, jp2_img_path)
    if Rails.env == "development" or Rails.env == "test"
      puts "assume the jp2 image was successfully moved"
    else
      repo_location = "#{ DIL_CONFIG[ 'jp2_location' ]}#{ jp2_img_name }"
      Sidekiq::Logging.logger.debug "UPLOADING ..."
      Sidekiq::Logging.logger.debug("scp cmd: scp -i #{ DIL_CONFIG['path_to_keyfile']} #{ jp2_img_path } #{ DIL_CONFIG['jp2_ssh_user'] }@#{DIL_CONFIG['jp2_server']}:#{DIL_CONFIG['jp2_location']}")

      stdout, stdeerr, status = Open3.capture3("scp -i #{ DIL_CONFIG['path_to_keyfile']} #{ jp2_img_path } #{ DIL_CONFIG['jp2_ssh_user'] }@#{DIL_CONFIG['jp2_server']}:#{DIL_CONFIG['jp2_location']}")
      Sidekiq::Logging.logger.debug("out #{stdout}")
      Sidekiq::Logging.logger.debug("err #{stdeerr}")
      Sidekiq::Logging.logger.debug("status #{status}")
      $?
    end
  end

  def self.move_img_to_repo(img_name, img_path)
    Sidekiq::Logging.logger.debug Rails.env
    Sidekiq::Logging.logger.debug img_name
    Sidekiq::Logging.logger.debug img_path

    if Rails.env == "development" or Rails.env == "test"
      Sidekiq::Logging.logger.debug "assume the image was successfully moved"

    else
      #needs to be in config --- just make /tmp owned by deploy on staging to fully mimic production
      if img_name.include?('.tif')
          new_path = "#{ DIL_CONFIG['repo_location']}#{ img_name }"
      elsif img_name.include?('.jp2')
        new_path = "#{DIL_CONFIG[ 'jp2_location' ]}#{ img_name }"
      else
        raise "Wrong image format, not tif or jp2"
      end

      old_path = img_path

      Sidekiq::Logging.logger.debug "Moving image file to #{new_path}"
      begin
        FileUtils.mkdir_p File.dirname(new_path)
        FileUtils.mv old_path, new_path
        Sidekiq::Logging.logger.info "#{old_path} has been moved to #{new_path}"
      rescue StandardError => e
        Sidekiq::Logging.logger.error "the copy failed because #{e}"
      end
    end

  end

  private

  def self.scp_mover( options )
    Sidekiq::Logging.logger.debug "UPLOADING ..."
    `scp #{ options[ :local_img_path ]} #{ options[:user] }@#{options[:server]}:#{options[:remote_img_path]} 2>&1`
    Sidekiq::Logging.logger.debug("full scp cmd #{ options[ :local_img_path ]} #{ options[:user] }@#{options[:server]}:#{options[:remote_img_path]}")
    Sidekiq::Logging.logger.debug $?
    Sidekiq::Logging.logger.debug "UPLOADING COMPLETE"
    $?
  end
end
