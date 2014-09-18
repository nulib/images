source 'http://rubygems.org'

  gem 'rails', '3.2.18'
  gem 'rack', '1.4.5'
  gem 'json', '1.7.7'
  gem 'blacklight', '4.2'
  gem 'kaminari', '~> 0.13'
  gem 'exception_notification', '3.0.1'
  gem 'ruby-prof'
  #gem 'om', '2.1.2'
  #gem 'hydra-access-controls', '0.0.5'
  gem 'hydra-head', '6.4.1'
  #gem 'hydra-mods', '0.0.5'
  gem 'sqlite3', '1.3.6'
  gem 'bootstrap-sass'
  gem 'rufus-scheduler', '3.0.2'

  # We will assume you're using devise in tutorials/documentation.
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise', '2.1.3'
  gem 'omniauth-ldap', '1.0.2'
  gem 'mysql2', '0.3.11'
  # gem 'clamav', '0.4.1'
  gem 'rdf', '1.0'
  gem 'gon'
  gem 'mini_exiftool'
  gem 'jhove-service'
  gem 'net-scp'
  gem 'delayed_job_active_record'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer', '0.10.1'
  gem 'bootstrap-sass'
  gem 'jquery-ui-rails', '1.0.0'
  gem "bootstrap-sass-rails", '2.0.3.0'
  gem 'ruby-xslt', '0.9.9'
end

gem "cancan", "1.6.7" # cancan 1.6.8 breaks PoliciesController.create method in a super strange way
gem 'jquery-rails', '2.0.2'
gem 'jquery.fileupload-rails', '0.1.1'

gem 'uuid', '2.3.5'
gem 'hydra-ldap', '0.0.3'
gem 'hydra-batch-edit', '~>0.0.6'

gem 'high_voltage'

group :development, :test, :staging do
  gem 'jettywrapper', '1.4.1'
  gem 'rspec-rails', '>=2.9.0'
  gem 'factory_girl_rails', '3.5.0'
  gem 'database_cleaner', '0.8.0'
  gem 'capybara', '1.1.2'
  gem 'bcrypt-ruby', '3.0.1'
  gem 'launchy', '2.1.0'
  gem 'simplecov', '0.7.1', :require => false, :group => :test
  gem 'debugger'
  gem 'capistrano3-unicorn' # I'm not 100% that this should be here, but i didn't want to create another group
end

gem 'unicorn', '4.3.1'

group :development do
  gem 'better_errors'
  gem 'sextant'
end

group :production do
  gem 'google-analytics-rails'
end

