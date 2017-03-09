h2. Developer prereqs

Ruby 2.x
git
java jre (at least 1.6, but 1.8 will be more future proof when we start to use fedora 4)

h2. Installation and Configuration

```
git clone https://github.com/nulib/images.git
bundle install
rake db:migrate
rake jetty:config
rake hydra:fixtures:refresh
rake db:test:prepare
```

h3. Local development only

You'll need to install imagemagick to handle the tiff to jp2 conversion on your local machine.
`brew install imagemagick --with-libtiff --with-jp2`

You'll also need redis running on port 6379
`brew install redis`
Then you can start sidekiq normally using `bundle exec sidekiq`

h2. Running the application

```
rake jetty:start
rails s
```

h2. Testing the application

To test the main image model, run:
```
rspec spec/models/multiresimage_spec.rb
```

The capybara-webkit tests require a WebKit implementation from Qt that can be installed with homebrew. See https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#homebrew for detailed installation instructions.

```
brew install qt@5.5
brew link --force qt55
```

After running this command you should get the following output:

```
$ which qmake
/usr/local/bin/qmake
```

Make sure to start jetty with `rake jetty:start` before running the tests.

To integration test the app, run:
```
rspec spec/features
```

You can run `rspec spec` to test the entire app.

h2. Deploying

We've got capistrano set up, so deploying *should* be as easy as 'cap environment deploy'.
Keep in mind that a deploy only copies over whatever files are in the public github repo, so many config files don't get copied during a deploy. You'll need to copy them over manually or run cap deploy setup.

h2. stuff to remember

the dropbox mount isn't managed by puppet

h2. new decisions

We're going to mount shares on images (both staging and prod) and use ImageMover and use FileUtils to move them around.

refer to the dil-config.yml for exact paths
