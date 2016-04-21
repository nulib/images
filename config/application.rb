require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the default gems listed in Gemfile, including only gems
# required for each environment.

Bundler.require(:default, Rails.env)

module DIL

  VERSION = "2.0"

  class Application < Rails::Application

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.assets.paths << "#{Rails}/vendor/assets/fonts"
    config.eager_load_paths += ["#{config.root}/app/workers"]

    config.assets.initialize_on_precompile = true
    config.exceptions_app = self.routes

    # Location where dil puts files to be processed
     config.processing_file_path = "/tmp"

     config.public_permission_levels = {
       "No Access"=>"none",
       "Discover" => "discover",
       "View" => "read"
     }
     config.permission_levels = {
       "No Access"=>"none",
       "Discover" => "discover",
       "View" => "read",
       "Edit" => "edit"
     }
  end
end
