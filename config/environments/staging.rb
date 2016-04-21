Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot.
  config.eager_load = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
#  config.action_mailer.delivery_method = :test
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.lograge.enabled = true

  config.lograge.custom_options = lambda do |event|
  params = event.payload[:params].reject do |k|
    ['controller', 'action'].include? k
  end

  { "params" => params }
  end

  # For emailing exceptions that occur in the app
  # config.middleware.use ExceptionNotifier,
  #   :email_prefix => "[DIL-Exception STAGING] ",
  #   :sender_address => %{"notifier" <edgar-garcia@northwestern.edu>},
  #   :exception_recipients => %w{edgar-garcia@northwestern.edu, christopher.syversen@northwestern.edu, brendan-quinn@northwestern.edu, p-clough@northwestern.edu}

end
