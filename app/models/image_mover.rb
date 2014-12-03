class ImageMover < ActiveRecord::Base

  DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]
  # This is sort of a weird class, but we created it so we could use the delayed_jobs gem to run the copying of huge tiff (and jp2) files to repository in the background and not effect the responsiveness of the entire app.

  def self.move_jp2_to_ansel(jp2_img_name, jp2_img_path)
    logger.debug Rails.env
    logger.debug jp2_img_name
    logger.debug jp2_img_path

    if Rails.env == "development"
      puts "assume the jp2 image was successfully moved"
    else
      sleep( 10 )
      repo_location = "#{ DIL_CONFIG[ 'jp2_location' ]}#{ jp2_img_name }"
      logger.debug repo_location

      logger.debug DIL_CONFIG[ 'jp2_server' ]
      logger.debug DIL_CONFIG[ 'jp2_ssh_user' ]
      scp_mover( server: DIL_CONFIG['jp2_server'], user: DIL_CONFIG[ 'jp2_ssh_user' ], password: DIL_CONFIG[ 'jp2_ssh_pw' ], local_img_path: jp2_img_path, remote_img_path: repo_location )
    end
  end


  def self.move_tiff_to_repo(tiff_img_name, tiff_img_path)
    logger.debug Rails.env
    logger.debug tiff_img_name
    logger.debug tiff_img_path

    if Rails.env == "development"
      puts "assume the tiff image was successfully moved"
    else
      repo_location = "#{ DIL_CONFIG[ 'repo_location' ]}#{ tiff_img_name }"
      logger.debug repo_location

      logger.debug DIL_CONFIG[ 'repo_server' ]
      logger.debug DIL_CONFIG[ 'repo_ssh_user' ]
      scp_mover( server: DIL_CONFIG['repo_server'], user: DIL_CONFIG[ 'repo_ssh_user' ], password: DIL_CONFIG[ 'repo_ssh_pw' ], local_img_path: tiff_img_path, remote_img_path: repo_location )
    end
  end



  private

  def self.scp_mover( options )

    logger.debug "UPLOADING ..."
    `scp #{ options[ :local_img_path ]} #{ options[:user] }@#{options[:server]}:#{options[:remote_img_path]} 2>&1`
    logger.debug $?
    logger.debug "UPLOADING COMPLETE"
  end
end

