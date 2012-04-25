source 'http://rubygems.org'

  gem 'rails', '3.2.2'
  gem 'blacklight', '3.3.1'
  gem 'hydra-head', :git=>'https://github.com/projecthydra/hydra-head.git' , :ref=>'dca91b9'
  gem 'active-fedora', :git=>'https://github.com/projecthydra/active_fedora.git', :ref=>'42e66b7'# > 4.0.0.rc20 
  gem 'sqlite3'
  
  #  We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'
  gem 'omniauth-ldap'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails', '~> 1.0.0'
  gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'
  # gem 'therubyracer'
  gem 'jquery-ui-rails'
  gem "bootstrap-sass-rails", :git=>'https://github.com/yabawock/bootstrap-sass-rails.git', :ref=>"3c68b13fff0d51406b73658869a39bb88fa1cd83" # due to pull request #12 which isn't in 2.0.2.2

end

gem 'jquery-rails'
gem 'jquery.fileupload-rails'

gem 'uuid'


group :development, :test do 
  gem 'jettywrapper'
  gem 'rspec-rails', '>=2.9.0'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'bcrypt-ruby'
end

gem 'unicorn'
