source 'http://rubygems.org' do

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
  gem 'mini_exiftool'
  gem 'jhove-service'
  gem 'protected_attributes'
  gem 'sinatra', :require => nil

  gem 'daemons'
  gem 'rubyntlm', '~> 0.1.1'
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rails', '~> 1.1.3'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq'

  gem 'jquery-ui-rails'
  gem "cancan"

  gem 'uuid'
  gem 'hydra-ldap'
  gem 'high_voltage'
  gem 'powerpoint', :git => 'https://github.com/benjaminwood/powerpoint.git'
  gem 'riiif'
  gem 'openseadragon'
  gem 'whenever', :require => false
  gem 'activerecord-session_store'

  group :test do
    gem 'rspec-rails'
    gem 'factory_girl_rails'
    gem 'database_cleaner'
    gem 'capybara'
    gem 'rspec-steps'
    gem 'capybara-webkit'
    gem 'launchy'
    gem 'simplecov', :require => false
    gem 'equivalent-xml', :git => 'https://github.com/mbklein/equivalent-xml.git'
  end

  group :development do
    gem 'jettywrapper'
    gem 'sqlite3'
    gem 'better_errors'
    gem 'binding_of_caller'
    gem 'sextant'
    gem 'rubocop', '~> 0.42.0', require: false
  end

  group :development, :test, :staging do
    gem 'byebug'
    gem 'pry'
    gem 'about_page', :git => 'https://github.com/sul-dlss/about_page.git'
  end

  group :staging, :production do
    gem 'pg'
    gem 'lograge'
  end

  group :production do
    gem 'google-analytics-rails'
  end
end

source "https://gems.contribsys.com/" do
  gem 'sidekiq-pro'
end
