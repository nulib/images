
FEDORA_CONFIG = YAML.load_file(Rails.root.join('config', 'fedora.yml'))[Rails.env]
DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]


Riiif::Image.file_resolver.base_path = "#{DIL_CONFIG['jp2_location']}"

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width
# cached in Solr. The following block directs the info_service to return those values:

HEIGHT_SOLR_FIELD = 'height_isi'
WIDTH_SOLR_FIELD = 'width_isi'
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
