source 'http://rubygems.org'

  gem 'rails', '~> 4.1.0'
  gem 'sass-rails', '>= 4'
  gem 'coffee-rails', '>= 4'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-rails'
  gem 'jbuilder', '~> 2.0'

  gem 'hydra-head', '~> 7.2.2'
  #gem 'bootstrap-sass', '~> 2'
  #gem 'json', '1.7.7'

  gem 'rufus-scheduler'
  gem 'devise' #, '2.1.3'
  gem 'omniauth-ldap', '1.0.2' # TODO: see if we're using this

  gem 'clamav'
  #gem 'rdf'
  gem 'gon'
  gem 'mini_exiftool'
  gem 'jhove-service'
  gem 'delayed_job_active_record'
  gem 'daemons'
  gem 'protected_attributes'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'

  gem 'therubyracer', '0.10.1'
  gem 'jquery-ui-rails'

  gem "cancan", "1.6.7" # cancan 1.6.8 breaks PoliciesController.create method in a super strange way

  gem 'jquery.fileupload-rails'

  gem 'uuid'
  gem 'hydra-ldap' #, '0.0.3'
  #gem 'hydra-batch-edit' #, '~>0.0.6'
  gem 'high_voltage'

group :development, :test, :staging do
  gem 'jettywrapper'
  gem 'sqlite3'
end

group :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'rspec-steps'
  gem 'dotenv-rails'
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
