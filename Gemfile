source 'http://rubygems.org'

  gem 'rails', '~> 4.1.0'
  gem 'sass-rails', '>= 4'
  gem 'coffee-rails', '>= 4'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-rails'
  gem 'jbuilder', '~> 2.0'
  gem 'rb-readline'

  gem 'hydra-head', '~> 8.0.0'

 gem 'rsolr'
 gem 'blacklight', '5.16.3'
 gem 'blacklight-marc'

  gem 'rufus-scheduler'
  gem 'devise'
  gem 'omniauth-ldap'

  gem 'gon'
  gem 'mini_exiftool'
  gem 'jhove-service'
  gem 'protected_attributes'
  gem 'sidekiq'
  gem 'sinatra', :require => nil

  gem 'daemons'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano-sidekiq'

  gem 'jquery-ui-rails'

  gem "cancan"

  gem 'uuid'
  gem 'hydra-ldap'
  gem 'high_voltage'
  gem 'powerpoint', :git => 'https://github.com/benjaminwood/powerpoint.git'

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

group :development, :remote_dev do
  gem 'about_page', :git => 'https://github.com/sul-dlss/about_page.git'
  gem 'jettywrapper'
  gem 'sqlite3'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'sextant'
  gem 'byebug'
  gem 'pry'
end

group :staging do
  gem 'pg'
  gem 'about_page', :git => 'https://github.com/sul-dlss/about_page.git'
  gem 'lograge'
end

group :production do
  gem 'pg'
  gem 'google-analytics-rails'
  gem 'lograge'
end
