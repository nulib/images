source 'http://rubygems.org'

  gem 'rails', '~> 4.1.0'
  gem 'sass-rails', '>= 4'
  gem 'coffee-rails', '>= 4'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-rails'
  gem 'jbuilder', '~> 2.0'

  gem 'hydra-head', '~> 7.2.2'

  gem 'rufus-scheduler'
  gem 'devise'
  gem 'omniauth-ldap'

  gem 'clamav'
  gem 'gon'
  gem 'mini_exiftool'
  gem 'jhove-service'
  gem 'protected_attributes'
  gem 'delayed_job_active_record'
  gem 'daemons'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'

  gem 'therubyracer'
  gem 'jquery-ui-rails'

  gem "cancan"

  gem 'uuid'
  gem 'hydra-ldap'
  gem 'high_voltage'

group :development, :test, :staging do
  gem 'jettywrapper'
  gem 'sqlite3'
  gem 'about_page', :git => 'git://github.com/sul-dlss/about_page.git'
end

group :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'rspec-steps'
  gem 'selenium-webdriver'
  gem 'launchy'
  gem 'simplecov', :require => false
  gem 'equivalent-xml', :git => 'https://github.com/mbklein/equivalent-xml.git'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'sextant'
  gem 'byebug'
end

group :production do
  gem 'mysql2'
  gem 'google-analytics-rails'
end