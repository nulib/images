
FEDORA_CONFIG = YAML.load_file(Rails.root.join('config', 'fedora.yml'))[Rails.env]
DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]

Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new
Riiif::Image.file_resolver.basic_auth_credentials = ["#{FEDORA_CONFIG['user']}", "#{FEDORA_CONFIG['password']}"]


DATASTREAM = 'DELIV-IMG'
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  connection = ActiveFedora::Base.connection_for_pid(id)
  host = connection.config[:url]
  path = connection.api.datastream_content_url(id, DATASTREAM, {})
  host + '/' + path
end

Riiif::Image.info_service = lambda do |id, file|
  img = id.gsub(/:/, "-")
  img_path = "#{DIL_CONFIG['jp2_location']}#{img}.jp2"
  info = Multiresimage.new.get_image_width_and_height(img_path)
  { height: info[:height], width: info[:width], scale_factors: [1, 2, 4, 8, 16, 32] }
end


def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
