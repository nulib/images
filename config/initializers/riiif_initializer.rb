
FEDORA_CONFIG = YAML.load_file(Rails.root.join('config', 'fedora.yml'))[Rails.env]
DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]

Riiif::Image.file_resolver.base_path = "#{DIL_CONFIG['jp2_location']}"

#overwriting info service to add scale factors -- probably not necessary but might be helpful
Riiif::Image.info_service = lambda do |id, file|
  Rails.cache.fetch(Riiif::Image.cache_key(id, { info: true }), compress: true, expires_in: Riiif::Image.expires_in) do
    file.info
    {height: file.info.height, width: file.info.width, scale_factors: [1, 2, 4, 8, 16, 32]}
  end
end


def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
