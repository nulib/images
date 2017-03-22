## Developer prereqs

* Ruby 2.x (managed via rbenv)
* git
* [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
* [Bundler](http://bundler.io")
* cmake: `brew install cmake`
* postgresql: `brew install postgresql`
* imagemagick to handle the tiff to jp2 conversion: `brew install imagemagick --with-ghostscript --with-openjpeg`
* redis running on port 6379 (default): `brew install redis`

## Installation and Configuration

* Clone the repository to your local computer `git clone git@github.com:nulib/images.git`
* Replace the `config/*.yml.example` configuration files with actual config values and rename to `.yml`
* Configure access to Sidekiq Pro (must obtain username/password) `bundle config gems.contribsys.com username:password`
* Replace `<images app>/jetty` with <i>known working jetty directory</i>
* `cd` inside the application directory and run `bundle install`
* Create the database `bundle exec rake db:migrate`
* Configure Jetty `bundle exec rake jetty:config`
* Start Jetty `bundle exec rake jetty:start`
* Refresh Hydra Fixture data `bundle exec rake hydra:fixtures:refresh
* Prepare the test database `bundle exec rake db:test:prepare`

### Local development only

You'll need to install imagemagick to handle the tiff to jp2 conversion on your local machine.
`brew install imagemagick --with-libtiff --with-jp2`

You'll also need redis running on port 6379
`brew install redis`
Then you can start sidekiq normally using `bundle exec sidekiq`

## Running the application

* `cd` to the application directory
* Start redis `redis-server`
* In a separate tab, start Sidekiq `bundle exec sidekiq`
* In a separate tab, start Fedora and Solr `rake jetty:start` (if not already running)
* Confirm Fedora is running on http://localhost:8983/fedora/
* Confirm Solr is running on http://localhost:8983/solr/#/
* In a separate tab, start the Rails app, specifying port 3331 `rails server -p 3331`
* Confirm the app is available at http://localhost:3331/

## Testing the application

You'll need to be connected to SSL VPN.

The capybara-webkit tests require a WebKit implementation from Qt that can be installed with homebrew. See [detailed instructions](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#homebrew).

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

Run `rspec spec` to test the entire app.

To test the main image model, run:
```
rspec spec/models/multiresimage_spec.rb
```

To integration test the app, run:
```
rspec spec/features
```

## Deployment

`cap [environment] deploy`
Keep in mind that a deploy only copies over whatever files are in the public github repo, so many config files don't get copied during a deploy.

We're going to mount shares on images (both staging and prod) and use ImageMover and use FileUtils to move them around.
