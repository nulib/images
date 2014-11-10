source 'http://rubygems.org'

  gem 'rails', '~> 4.1'
  gem 'sqlite3'
  gem 'sass-rails', '>= 4'
  gem 'coffee-rails', '>= 4'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-rails'
  gem 'jbuilder', '~> 2.0'

  gem 'hydra-head', '~> 6.4'

  gem 'json', '1.7.7'
  gem 'bootstrap-sass', '~>2'
  gem 'rufus-scheduler', '3.0.2'
  gem 'devise' #, '2.1.3'
  gem 'omniauth-ldap', '1.0.2'
  gem 'mysql2', '0.3.11'
  gem 'clamav', '0.4.1'
  gem 'rdf', '1.0'
  gem 'gon'
  gem 'mini_exiftool'
  gem 'jhove-service'
  gem 'net-scp'
  gem 'delayed_job_active_record'
  gem 'protected_attributes'
  gem 'binding_of_caller'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'daemons'
  gem 'therubyracer', '0.10.1'
  gem 'jquery-ui-rails'

  gem "cancan", "1.6.7" # cancan 1.6.8 breaks PoliciesController.create method in a super strange way

  gem 'jquery.fileupload-rails'

  gem 'uuid', '2.3.5'
  gem 'hydra-ldap', '0.0.3'
  gem 'hydra-batch-edit', '~>0.0.6'
  gem 'unicorn', '4.3.1'
  gem 'high_voltage'

group :development, :test, :staging do
  gem 'jettywrapper' #, '1.4.1'
  gem 'bcrypt-ruby'
  gem 'capistrano3-unicorn' # I'm not 100% that this should be here, but i didn't want to create another group
end

group :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'rspec-steps'
  gem 'dotenv-rails'
end

group :development do
  gem 'better_errors'
  gem 'sextant'
  gem 'equivalent-xml', :git => 'https://github.com/mbklein/equivalent-xml.git'
  gem 'launchy'
  gem 'simplecov', :require => false
  gem 'byebug'
end

group :production do
  gem 'google-analytics-rails'
end
