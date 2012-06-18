source 'http://rubygems.org'

  gem 'rails', '3.2.5'
  gem 'blacklight', :git=>'git://github.com/projectblacklight/blacklight.git', :ref=>'a83c286'
  gem 'hydra-head', :git=>'git://github.com/projecthydra/hydra-head.git' , :ref=>'ca10693'
  gem 'active-fedora', '4.2.0'
  gem 'sqlite3'
  
  #  We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'
  gem 'omniauth-ldap'
  gem 'mysql2'
  gem 'clamav'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails', '~> 1.0.0'
  gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'
  gem 'therubyracer'
  gem 'jquery-ui-rails'
  gem "bootstrap-sass-rails", '2.0.3.0'

end

gem 'jquery-rails'
gem 'jquery.fileupload-rails'

gem 'uuid'
gem 'hydra-ldap', '~>0.0.3'
gem 'hydra-batch-edit', '~>0.0.4'

group :development, :test do 
  gem 'jettywrapper'
  gem 'rspec-rails', '>=2.9.0'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'bcrypt-ruby'
  gem 'debugger'
  gem 'launchy'
end

gem 'unicorn'
