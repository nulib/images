
FEDORA_CONFIG = YAML.load_file(Rails.root.join('config', 'fedora.yml'))[Rails.env]
DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]

Riiif::Image.file_resolver.base_path = "#{DIL_CONFIG['jp2_location']}"

def logger
  Rails.logger
end

Riiif::Engine.config.cache_duration_in_days = 30
