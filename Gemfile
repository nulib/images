source 'http://rubygems.org'

  gem 'rails', '3.2.2'
  gem 'blacklight', '3.3.1'
  gem 'hydra-head', :git=>'git://github.com/projecthydra/hydra-head.git', :ref=>'90a323e'# > 4.0.0.rc5 
  gem 'sqlite3'
  
  #  We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'

  # For testing.  You will probably want to use all of these to run the tests you write for your hydra head
  group :development, :test do 
         gem 'jettywrapper'
         gem 'rspec-rails', '>=2.9.0'
         gem 'cucumber-rails'
         gem 'database_cleaner'
         gem 'capybara'
         gem 'bcrypt-ruby'
  end

  gem 'unicorn'
