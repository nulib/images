
FEDORA_CONFIG = YAML.load_file(Rails.root.join('config', 'fedora.yml'))[Rails.env]

# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new
Riiif::Image.file_resolver.basic_auth_credentials = ["#{FEDORA_CONFIG['user']}", "#{FEDORA_CONFIG['password']}"]

# This tells RIIIF how to resolve the identifier to a URI in Fedora
DATASTREAM = 'DELIV-IMG'
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  connection = ActiveFedora::Base.connection_for_pid(id)
  #logger.info("okay is this in the pid? #{id}")
  host = connection.config[:url]
  path = connection.api.datastream_content_url(id, DATASTREAM, {})
  #logger.info("or the path? #{path}")
  host + '/' + path
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width
# cached in Solr. The following block directs the info_service to return those values:
HEIGHT_SOLR_FIELD = 'height_isi'
WIDTH_SOLR_FIELD = 'width_isi'
Riiif::Image.info_service = lambda do |id, file|
  height = Multiresimage.find(id).DELIV_OPS.svg_image.svg_height.first.to_i
  width = Multiresimage.find(id).DELIV_OPS.svg_image.svg_width.first.to_i
  { height: height, width: width, scale_factors: [1, 2, 4, 8, 16, 32] }
end

include Blacklight::SolrHelper
def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
