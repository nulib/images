class ImageMover < ActiveRecord::Base

  DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]
  # This is sort of a weird class, but we created it so we could use the delayed_jobs gem to run the copying of huge tiff (and jp2) files to repository in the background and not effect the responsiveness of the entire app.

  def self.move_jp2_to_ansel(jp2_img_name, jp2_img_path)
    Delayed::Worker.logger.debug Rails.env
    Delayed::Worker.logger.debug jp2_img_name
    Delayed::Worker.logger.debug jp2_img_path

    if Rails.env == "development" or Rails.env == "test"
      puts "assume the jp2 image was successfully moved"
    else
      #sleep( 10 )
      repo_location = "#{ DIL_CONFIG[ 'jp2_location' ]}#{ jp2_img_name }"
      Delayed::Worker.logger.debug repo_location

      Delayed::Worker.logger.debug DIL_CONFIG[ 'jp2_server' ]
      Delayed::Worker.logger.debug DIL_CONFIG[ 'jp2_ssh_user' ]
      #going to want status = scp results and to return it here too.
      scp_mover( server: DIL_CONFIG['jp2_server'], user: DIL_CONFIG[ 'jp2_ssh_user' ], local_img_path: jp2_img_path, remote_img_path: repo_location )
    end
  end


  def self.move_tiff_to_repo(tiff_img_name, tiff_img_path)
    Delayed::Worker.logger.debug Rails.env
    Delayed::Worker.logger.debug tiff_img_name
    Delayed::Worker.logger.debug tiff_img_path

    if Rails.env == "development" or Rails.env == "test"
      Delayed::Worker.logger.debug "assume the tiff image was successfully moved"
    else
      repo_location = "#{ DIL_CONFIG[ 'repo_location' ]}#{ tiff_img_name }"
      logger.debug repo_location

      logger.debug DIL_CONFIG[ 'repo_server' ]
      logger.debug DIL_CONFIG[ 'repo_ssh_user' ]
      status = scp_mover( server: DIL_CONFIG['repo_server'], user: DIL_CONFIG[ 'repo_ssh_user' ], local_img_path: tiff_img_path, remote_img_path: repo_location )
      status
    end

  end

  private

  def self.scp_mover( options )
    Delayed::Worker.logger.debug "UPLOADING ..."
    `scp -i #{ options[:path_to_keyfile]} #{ options[ :local_img_path ]} #{ options[:user] }#{options[:server]}:#{options[:remote_img_path]} 2>&1`
    #{}`scp #{ options[ :local_img_path ]} #{ options[:user] }@#{options[:server]}:#{options[:remote_img_path]} 2>&1`
    Delayed::Worker.logger.debug("full scp cmd #{ options[ :local_img_path ]} #{ options[:user] }@#{options[:server]}:#{options[:remote_img_path]}")

    Delayed::Worker.logger.debug $?
    Delayed::Worker.logger.debug "UPLOADING COMPLETE"
    $?
  end
end
