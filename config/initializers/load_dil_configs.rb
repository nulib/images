DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[Rails.env]
ActiveSupport::XmlMini::PARSING.delete("symbol")
ActiveSupport::XmlMini::PARSING.delete("yaml") 