class Jp2Helper < ActiveRecord::Base
  def self.move_jp2_to_ansel(jp2_img_name, jp2_img_path)

    require 'net/scp'

    if Rails.env == "development"
      puts "assume the jp2 image was successfully moved"
    else
      ansel_location = "#{ DIL_CONFIG[ 'ansel_location' ]}/#{ jp2_img_name }"
      ansel_user     = DIL_CONFIG[ 'ssh_user' ]
      ansel_password = DIL_CONFIG[ 'ssh_pw' ]
      # Move jp2 file to ansel
      Net::SCP.upload!( "ansel.library.northwestern.edu",
                        ansel_user,
                        jp2_img_path,
                        ansel_location,
                        ssh: { password: ansel_password })
    end
  end


  def self.move_tiff_to_repo(tiff_img_name, tiff_img_path)

  end
end