require 'open3'

class ImageMover < ActiveRecord::Base

  DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]

  def self.move_jp2_to_ansel(jp2_img_name, jp2_img_path)
    if Rails.env == "development" or Rails.env == "test"
      puts "assume the jp2 image was successfully moved"
    else
      repo_location = "#{ DIL_CONFIG[ 'jp2_location' ]}#{ jp2_img_name }"
      $?
    end
  end

  def self.move_img_to_repo(img_name, img_path)
    if Rails.env == "development" or Rails.env == "test"
      # NOOP
    else
      if img_name.include?('.tif')
          new_path = "#{ DIL_CONFIG['repo_location']}#{ img_name }"
      elsif img_name.include?('.jp2')
        new_path = "#{DIL_CONFIG[ 'jp2_location' ]}#{ img_name }"
      else
        raise "Wrong image format, not tif or jp2"
      end
      old_path = img_path

      begin
        FileUtils.mkdir_p File.dirname(new_path)
        FileUtils.mv old_path, new_path
      rescue StandardError => e
        # NOOP
      end
    end
  end

  private

  def self.scp_mover( options )
    `scp #{ options[ :local_img_path ]} #{ options[:user] }@#{options[:server]}:#{options[:remote_img_path]} 2>&1`
    $?
  end
end
